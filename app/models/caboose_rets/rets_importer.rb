#require 'ruby-rets'
require "rets/version"
require "rets/exceptions"
require "rets/client"
require "rets/http"
require "rets/stream_http"
require "rets/base/core"
require "rets/base/sax_search"
require "rets/base/sax_metadata"

require 'httparty'
require 'json'

# http://rets.solidearth.com/ClientHome.aspx

class CabooseRets::RetsImporter # < ActiveRecord::Base

  @@rets_client = nil   
  @@config = nil

  def self.config
    return @@config
  end

  def self.get_config
    @@config = {
      'url'                 => nil, # URL to the RETS login
      'username'            => nil,
      'password'            => nil,
      'temp_path'           => nil,
      'log_file'            => nil,
      'media_base_url'      => nil
    }
    config = YAML::load(File.open("#{Rails.root}/config/rets_importer.yml"))    
    config = config[Rails.env]
    config.each { |key,val| @@config[key] = val }
  end

  def self.client
    self.get_config if @@config.nil? || @@config['url'].nil?

    if @@rets_client.nil?
      @@rets_client = RETS::Client.login(
        :url      => @@config['url'],
        :username => @@config['username'],
        :password => @@config['password']
      )
    end
    return @@rets_client
  end

  def self.meta(class_type)
    case class_type
      when 'Office'    then Caboose::StdClass.new({ :search_type => 'Office'    , :remote_key_field => 'Matrix_Unique_ID' , :local_key_field => 'matrix_unique_id'    , :local_table => 'rets_offices'      , :date_modified_field => 'MatrixModifiedDT'})
      when 'Agent'     then Caboose::StdClass.new({ :search_type => 'Agent'     , :remote_key_field => 'Matrix_Unique_ID' , :local_key_field => 'matrix_unique_id'    , :local_table => 'rets_agents'       , :date_modified_field => 'MatrixModifiedDT'})
      when 'OpenHouse' then Caboose::StdClass.new({ :search_type => 'OpenHouse' , :remote_key_field => 'matrix_unique_id' , :local_key_field => 'matrix_unique_id'    , :local_table => 'rets_open_houses'  , :date_modified_field => 'MatrixModifiedDT'})
      when 'Listing'   then Caboose::StdClass.new({ :search_type => 'Property'  , :remote_key_field => 'Matrix_Unique_ID' , :local_key_field => 'matrix_unique_id'    , :local_table => 'rets_properties'   , :date_modified_field => 'MatrixModifiedDT'})
      when 'GFX'       then Caboose::StdClass.new({ :search_type => 'Media'     , :remote_key_field => 'MEDIA_ID'         , :local_key_field => 'media_id'            , :local_table => 'rets_media'        , :date_modified_field => 'DATE_MODIFIED'   })
      end
  end

  #=============================================================================
  # Import method
  #=============================================================================

  def self.import(class_type, query)
    m = self.meta(class_type)
    self.log("Importing #{m.search_type}:#{class_type} with query #{query}...")
    self.get_config if @@config.nil? || @@config['url'].nil?
    params = {
      :search_type => m.search_type,
      :class => class_type,
      :query => query,
      :timeout => -1
    }
    obj = nil

    begin
      self.client.search(params) do |data|
        obj = self.get_instance_with_id(class_type, data)
        if obj.nil?
          self.log("Error: object is nil")
          self.log(data.inspect)
          next
        end
        obj.parse(data)
        obj.save
      end
    rescue RETS::HTTPError => err
      self.log "Import error for #{class_type}: #{query}"
      self.log err.message
    end
  end

  def self.get_instance_with_id(class_type, data)
    obj = nil
    m = case class_type
      when 'Listing'   then CabooseRets::Property
      when 'OpenHouse' then CabooseRets::OpenHouse
      when 'Agent'     then CabooseRets::Agent
      when 'Office'    then CabooseRets::Office
      when 'GFX'       then CabooseRets::Media
    end  
    obj  = case class_type
      when 'Listing'   then m.where(:matrix_unique_id => data['Matrix_Unique_ID']).exists? ? m.where(:matrix_unique_id => data['Matrix_Unique_ID']).first : m.new(:matrix_unique_id => data['Matrix_Unique_ID'])
      when 'OpenHouse' then m.where(:matrix_unique_id => data['matrix_unique_id']).exists? ? m.where(:matrix_unique_id => data['matrix_unique_id']).first : m.new(:matrix_unique_id => data['matrix_unique_id'])
      when 'Agent'     then m.where(:matrix_unique_id => data['Matrix_Unique_ID']).exists? ? m.where(:matrix_unique_id => data['Matrix_Unique_ID']).first : m.new(:matrix_unique_id => data['Matrix_Unique_ID'])
      when 'Office'    then m.where(:matrix_unique_id => data['Matrix_Unique_ID']).exists? ? m.where(:matrix_unique_id => data['Matrix_Unique_ID']).first : m.new(:matrix_unique_id => data['Matrix_Unique_ID'])
      when 'GFX'       then m.where(:media_id => data['MEDIA_ID']      ).exists? ? m.where(:media_id => data['MEDIA_ID']      ).first : m.new(:media_id => data['MEDIA_ID']      )
    end
    return obj
  end

  #=============================================================================
  # Main updater
  #=============================================================================

  def self.update_after(date_modified, save_images = true)
    self.delay(:priority => 10, :queue => 'rets').update_helper('Listing'  , date_modified, save_images)
    self.delay(:priority => 10, :queue => 'rets').update_helper('Office'   , date_modified, save_images)
    self.delay(:priority => 10, :queue => 'rets').update_helper('Agent'    , date_modified, save_images)
    self.delay(:priority => 10, :queue => 'rets').update_helper('OpenHouse', date_modified, save_images)
  end

  def self.update_helper(class_type, date_modified, save_images = true)    
    m = self.meta(class_type)
    k = m.remote_key_field
    d = date_modified.in_time_zone(CabooseRets::timezone).strftime("%FT%T")
    params = {
      :search_type => m.search_type,
      :class => class_type,
      :select => [m.remote_key_field],
      :querytype => 'DMQL2',
      :query => "(#{m.date_modified_field}=#{d}+)",
      :standard_names_only => true,
      :timeout => -1
    }    
    self.log(params)
    self.client.search(params) do |data|    
      case class_type
        when 'Listing'   then self.delay(:priority => 10, :queue => 'rets').import_properties(data[k], save_images)
        when 'Office'    then self.delay(:priority => 10, :queue => 'rets').import_office(    data[k], save_images)
        when 'Agent'     then self.delay(:priority => 10, :queue => 'rets').import_agent(     data[k], save_images)
        when 'OpenHouse' then self.delay(:priority => 10, :queue => 'rets').import_open_house(data[k], save_images)
      end
    end
  end

  #=============================================================================
  # Single model import methods (called from a worker dyno)
  #=============================================================================

  # def self.import_property(mui, save_images = true)
  #   self.import('Listing', "(Matrix_Unique_ID=#{mui})")
  #   p = CabooseRets::Property.where(:matrix_unique_id => mui.to_s).first
  #   if p != nil
  #     self.download_property_images(p)
  #     self.update_coords(p)
  #   else
  #     self.log("No Property associated with #{mui}")
  #   end
  # end

  def self.import_properties(mui, save_images = true)
    self.import('Listing', "(Matrix_Unique_ID=#{mui})")
    p = CabooseRets::Property.where(:matrix_unique_id => mui.to_s).first
    # p = CabooseRets::Property.create(:matrix_unique_id => mui.to_s) if p.nil?
    if p != nil
      self.download_property_images(p)
      self.update_coords(p)
    else
      self.log("No Property associated with #{mui}")
    end
  end

  def self.import_office(mui, save_images = true)
    self.import('Office', "(matrix_unique_id=#{mui})")
    office = CabooseRets::Office.where(:matrix_unique_id => mui.to_s).first
    # self.download_office_image(office) if save_images == true
  end

  def self.import_agent(mui, save_images = true)
    self.import('Agent', "(Matrix_Unique_ID=#{mui})")
    a = CabooseRets::Agent.where(:matrix_unique_id => mui.to_s).first
    # self.download_agent_image(a) #if save_images == true
  end

  def self.import_open_house(mui, save_images = true)
    self.import('OpenHouse', "(Matrix_Unique_ID=#{mui})")
  end

  def self.import_media(id, save_images = true)
    self.import('GFX', "((MEDIA_ID=#{id}+),(MEDIA_ID=#{id}-))")
  end

  #=============================================================================
  # Images
  #=============================================================================

  # def self.download_property_images(p, save_images = true)
  #   return if save_images == false

  #   self.log("- Downloading GFX records for #{p.matrix_unique_id}...")
  #   params = {
  #     :search_type => 'Media',
  #     :class => 'Photo',
  #     :type => 'Photo',
  #     :resource => 'Property',
  #     :query => "(ID=*#{p.matrix_unique_id}:1*)",
  #     :limit => 1000,
  #     :timeout => -1
  #   }
  #   ids = []
  #   self.client.search(params) do |data|
  #     puts data
  #     ids << data['MEDIA_ID']
  #     m = CabooseRets::Media.where(:media_id => data['MEDIA_ID']).first
  #     m = CabooseRets::Media.new if m.nil?
  #     data.MEDIA_MUI = p.matrix_unique_id
  #     m.parse(data)
  #     m.save
  #   end

  #   if ids.count > 0
  #     # Delete any records in the local database that shouldn't be there
  #     self.log("- Deleting GFX records for MLS ##{p.matrix_unique_id} in the local database that are not in the remote database...")
  #     query = "select media_id from rets_media where matrix_unique_id = '#{p.matrix_unique_id}'"
  #     rows = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql_array, query))
  #     local_ids = rows.collect{ |row| row['media_id'] }
  #     ids_to_remove = local_ids - ids
  #     if ids_to_remove && ids_to_remove.count > 0
  #       query = ["delete from rets_media where media_id in (?)", ids_to_remove]
  #       ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, query))
  #     end
  #   end
  # end

  def self.download_property_images(p)
    self.log "Saving images for #{p.matrix_unique_id}..."
    begin
      # url = "http://rets.wamls.mlsmatrix.com/rets/GetObject.ashx?Type=Photo&Resource=Property&ID=1026514:1"
      self.client.get_object(:resource => 'Property', :type => 'Photo', :location=> false, :id => "#{p.matrix_unique_id}:*") do |headers, content|
        m = CabooseRets::Media.where(:media_mui => headers['content-id'], :media_order => headers['object-id']).first
        m = CabooseRets::Media.new if m.nil?

        tmp_path = "#{Rails.root}/tmp/rets_media_#{headers['content-id']}:#{headers['object-id']}.jpeg"

        # Temporarily cache content
        File.open(tmp_path, "wb") do |f|
          f.write(content)
        end

        # Parse downloaded content
        m.media_mui     = headers['content-id']
        m.media_order   = headers['object-id']
        m.media_remarks = headers['content-description']
        m.media_type    = 'Photo'

        cm               = Caboose::Media.new
        cm.image         = File.open(tmp_path)
        cm.name          = "rets_media_#{headers['content-id']}_#{headers['object-id']}"
        cm.original_name = "rets_media_#{headers['content-id']}_#{headers['object-id']}.jpeg"
        cm.processed     = true
        cm.save

        m.media_id = cm.id
        m.save

        # Remove temporary file
        `rm #{tmp_path}`

        self.log("Image #{headers['content-id']}:#{headers['object-id']} saved")
      end
    rescue RETS::APIError => err
      self.log "No image for #{p.matrix_unique_id}."
      self.log err
    end
  end

  def self.download_agent_image(agent)
    self.log "Saving image for #{agent.first_name} #{agent.last_name}..."
    begin
      self.client.get_object(:resource => :Agent, :type => :Photo, :location => true, :id => property.list_agent_mls_id) do |headers, content|
        agent.verify_meta_exists
        agent.meta.image_location = headers['location']
        agent.meta.save
      end
    rescue RETS::APIError => err
      self.log "No image for #{agent.first_name} #{agent.last_name}."
      self.log err
    end
  end

  def self.download_office_image(office)
    #self.log "Saving image for #{agent.first_name} #{agent.last_name}..."
    #begin
    #  self.client.get_object(:resource => :Agent, :type => :Photo, :location => true, :id => agent.la_code) do |headers, content|
    #    agent.verify_meta_exists
    #    agent.meta.image_location = headers['location']
    #    agent.meta.save
    #  end
    #rescue RETS::APIError => err
    #  self.log "No image for #{agent.first_name} #{agent.last_name}."
    #  self.log err
    #end
  end

  #=============================================================================
  # GPS
  #=============================================================================

  def self.update_coords(p = nil)
    if p.nil?
      model = CabooseRets::Property      
      i = 0      
        self.log "Updating coords properties..."
        model.where(:latitude => nil).reorder(:matrix_unique_id).each do |p1|
          self.delay(:priority => 10, :queue => 'rets').update_coords(p1)
        end
      return
    end

    self.log "Getting coords for Matrix_Unique_ID #{p.matrix_unique_id}..."
    coords = self.coords_from_address(CGI::escape "#{p.street_number} #{p.street_name}, #{p.city}, #{p.state_or_province} #{p.postal_code}")
    if coords.nil? || coords == false
      self.log "Can't set coords for Matrix_Unique_ID #{p.matrix_unique_id}..."
      return
    end

    p.latitude = coords['lat']
    p.longitude = coords['lng']
    p.save
  end

  def self.coords_from_address(address)
    #return false
    begin
      uri = "https://maps.googleapis.com/maps/api/geocode/json?address=#{address}&sensor=false"
      uri.gsub!(" ", "+")
      resp = HTTParty.get(uri)
      json = JSON.parse(resp.body)
      return json['results'][0]['geometry']['location']
    rescue
      self.log "Error: #{uri}"
      sleep(2)
      return false
    end
  end

  #=============================================================================
  # Purging
  #=============================================================================

  def self.purge
    self.log('purging')
    self.purge_properties
    self.purge_offices
    #self.purge_agents
    self.purge_open_houses
  end  
  
  def self.purge_properties()   self.delay(:priority => 10, :queue => 'rets').purge_helper('Listing', '2012-01-01') end
  def self.purge_offices()      self.delay(:priority => 10, :queue => 'rets').purge_helper('Office', '2012-01-01') end
  def self.purge_agents()       self.delay(:priority => 10, :queue => 'rets').purge_helper('Agent', '2012-01-01') end
  def self.purge_open_houses()  self.delay(:priority => 10, :queue => 'rets').purge_helper('OpenHouse', '2012-01-01') end
  

  def self.purge_helper(class_type, date_modified)    
    m = self.meta(class_type)    
    self.log(m.search_type)

    self.log("Purging #{class_type}...")

    # Get the total number of records
    self.log("- Getting total number of records for #{class_type}...")
    params = {
      :search_type => m.search_type,
      :class => class_type,
      :query => "(#{m.date_modified_field}=#{date_modified}T00:00:01+)",
      :standard_names_only => true,
      :timeout => -1
    }
    count = 0
    self.client.search(params.merge({ :count => 1})) do |data| end        
    count = self.client.rets_data[:code] == "20201" ? 0 : self.client.rets_data[:count]    
    batch_count = (count.to_f/5000.0).ceil

    ids = []
    k = m.remote_key_field
    (0...batch_count).each do |i|
      self.log("- Getting ids for #{class_type} (batch #{i+1} of #{batch_count})...")
      self.client.search(params.merge({ :select => [k], :limit => 5000, :offset => 5000*i })) do |data|
        ids << (class_type == 'OpenHouse' ? data[k].to_i : data[k])
      end
    end

    # Only do stuff if we got a real response from the server
    if ids.count > 0

      # Delete any records in the local database that shouldn't be there
      self.log("- Finding #{class_type} records in the local database that are not in the remote database...")
      t = m.local_table
      k = m.local_key_field
      query = "select distinct #{k} from #{t}"
      rows = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql_array, query))
      local_ids = rows.collect{ |row| row[k] }
      ids_to_remove = local_ids - ids
      self.log("- Found #{ids_to_remove.count} #{class_type} records in the local database that are not in the remote database.")
      self.log("- Deleting #{class_type} records in the local database that shouldn't be there...")
      query = ["delete from #{t} where #{k} in (?)", ids_to_remove]
      ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, query))

      # Find any ids in the remote database that should be in the local database
      self.log("- Finding #{class_type} records in the remote database that should be in the local database...")
      query = "select distinct #{k} from #{t}"
      rows = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql_array, query))
      local_ids = rows.collect{ |row| row[k] }
      ids_to_add = ids - local_ids
      ids_to_add = ids_to_add.sort.reverse
      self.log("- Found #{ids_to_add.count} #{class_type} records in the remote database that we need to add to the local database.")
      ids_to_add.each do |id|
        self.log("- Importing #{id}...")
        case class_type
          when "Listing"   then self.delay(:priority => 10, :queue => 'rets').import_properties(id, false)
          when "Office"    then self.delay(:priority => 10, :queue => 'rets').import_office(id, false)
          when "Agent"     then self.delay(:priority => 10, :queue => 'rets').import_agent(id, false)
          when "OpenHouse" then self.delay(:priority => 10, :queue => 'rets').import_open_house(id, false)
        end
      end
    end
  end

  def self.get_media_urls
    m = self.meta(class_type)

    # Get the total number of records
    params = {
      :search_type => m.search_type,
      :class => class_type,
      :query => "(#{m.matrix_modified_dt}=#{date_modified}T00:00:01+)",
      :standard_names_only => true,
      :timeout => -1
    }
    self.client.search(params.merge({ :count => 1 }))
    count = self.client.rets_data[:code] == "20201" ? 0 : self.client.rets_data[:count]
    batch_count = (count.to_f/5000.0).ceil

    ids = []
    k = m.remote_key_field
    (0...batch_count).each do |i|
      self.client.search(params.merge({ :select => [k], :limit => 5000, :offset => 5000*i })) do |data|
        ids << data[k]
      end
    end

    if ids.count > 0
      # Delete any records in the local database that shouldn't be there
      t = m.local_table
      k = m.local_key_field
      query = ["delete from #{t} where #{k} not in (?)", ids]
      ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, query))

      # Find any ids in the remote database that should be in the local database
      query = "select distinct #{k} from #{t}"      
      rows = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql_array, query))
      local_ids = rows.collect{ |row| row[k] }
      ids_to_add = ids - local_ids
      ids_to_add.each do |id|
        self.log("Importing #{id}...")
        case class_type
          when "Listing"   then self.delay(:priority => 10, :queue => 'rets').import_properties(id, false)
          when "Office"    then self.delay(:priority => 10, :queue => 'rets').import_office(id, false)
          when "Agent"     then self.delay(:priority => 10, :queue => 'rets').import_agent(id, false)
          when "OpenHouse" then self.delay(:priority => 10, :queue => 'rets').import_open_house(id, false)
        end
      end
    end

  end

  #=============================================================================
  # Logging
  #=============================================================================

  def self.log(msg)
    puts "[rets_importer] #{msg}"
    #Rails.logger.info("[rets_importer] #{msg}")
  end

  def self.log2(msg)
    puts "======================================================================"
    puts "[rets_importer] #{msg}"
    puts "======================================================================"
    #Rails.logger.info("[rets_importer] #{msg}")
  end

  #=============================================================================
  # Locking update task
  #=============================================================================

  def self.update_rets
    self.log2("Updating rets...")
    if self.task_is_locked
      self.log2("Task is locked, aborting.")
      return
    end
    self.log2("Locking task...")
    task_started = self.lock_task

    begin
      overlap = 30.seconds
      if (DateTime.now - self.last_purged).to_i >= 1
        self.purge
        self.save_last_purged(task_started)
        # Keep this in here to make sure all updates are caught
        #overlap = 1.month
      end

      self.log2("Updating after #{self.last_updated.strftime("%FT%T%:z")}...")
      self.update_after(self.last_updated - overlap)

      self.log2("Saving the timestamp for when we updated...")
		  self.save_last_updated(task_started)

		  self.log2("Unlocking the task...")
		  self.unlock_task
		rescue Exception => err
		  puts err
		  raise
		ensure
		  self.log2("Unlocking task if last updated...")
		  self.unlock_task_if_last_updated(task_started)
    end

		# Start the same update process in five minutes
		self.log2("Adding the update rets task for 20 minutes from now...")
		q = "handler like '%update_rets%'"
		count = Delayed::Job.where(q).count
		if count == 0 || (count == 1 && Delayed::Job.where(q).first.locked_at)
		  self.delay(:run_at => 20.minutes.from_now, :priority => 10, :queue => 'rets').update_rets
		end
  end

  def self.last_updated
    if !Caboose::Setting.exists?(:name => 'rets_last_updated')
      Caboose::Setting.create(:name => 'rets_last_updated', :value => '2013-08-06T00:00:01')
    end
    s = Caboose::Setting.where(:name => 'rets_last_updated').first
    return DateTime.parse(s.value)
  end

  def self.last_purged
    if !Caboose::Setting.exists?(:name => 'rets_last_purged')
      Caboose::Setting.create(:name => 'rets_last_purged', :value => '2013-08-06T00:00:01')
    end
    s = Caboose::Setting.where(:name => 'rets_last_purged').first
    return DateTime.parse(s.value)
  end

  def self.save_last_updated(d)
    s = Caboose::Setting.where(:name => 'rets_last_updated').first
    s.value = d.in_time_zone(CabooseRets::timezone).strftime("%FT%T%:z")
    s.save
  end

  def self.save_last_purged(d)
    s = Caboose::Setting.where(:name => 'rets_last_purged').first
    s.value = d.in_time_zone(CabooseRets::timezone).strftime("%FT%T%:z")
    s.save
  end

  def self.task_is_locked
    return Caboose::Setting.exists?(:name => 'rets_update_running')
  end

  def self.lock_task
    d = DateTime.now.utc.in_time_zone(CabooseRets::timezone)
    Caboose::Setting.create(:name => 'rets_update_running', :value => d.strftime("%FT%T%:z"))
    return d
  end

  def self.unlock_task
    Caboose::Setting.where(:name => 'rets_update_running').first.destroy
  end

  def self.unlock_task_if_last_updated(d)
    setting = Caboose::Setting.where(:name => 'rets_update_running').first
    self.unlock_task if setting && d.in_time_zone.strftime("%FT%T%:z") == setting.value
  end

end
