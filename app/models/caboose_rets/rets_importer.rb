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
      when 'RES' then Caboose::StdClass.new({ :search_type => 'Property'  , :remote_key_field => 'MLS_ACCT'   , :local_key_field => 'mls_acct' , :local_table => 'rets_residential'  , :date_modified_field => 'DATE_MODIFIED'    })
      when 'COM' then Caboose::StdClass.new({ :search_type => 'Property'  , :remote_key_field => 'MLS_ACCT'   , :local_key_field => 'mls_acct' , :local_table => 'rets_commercial'   , :date_modified_field => 'DATE_MODIFIED'    })
      when 'LND' then Caboose::StdClass.new({ :search_type => 'Property'  , :remote_key_field => 'MLS_ACCT'   , :local_key_field => 'mls_acct' , :local_table => 'rets_land'         , :date_modified_field => 'DATE_MODIFIED'    })
      when 'MUL' then Caboose::StdClass.new({ :search_type => 'Property'  , :remote_key_field => 'MLS_ACCT'   , :local_key_field => 'mls_acct' , :local_table => 'rets_multi_family' , :date_modified_field => 'DATE_MODIFIED'    })
      when 'OFF' then Caboose::StdClass.new({ :search_type => 'Office'    , :remote_key_field => 'LO_LO_CODE' , :local_key_field => 'lo_code'  , :local_table => 'rets_offices'      , :date_modified_field => 'LO_DATE_MODIFIED' })
      when 'AGT' then Caboose::StdClass.new({ :search_type => 'Agent'     , :remote_key_field => 'LA_LA_CODE' , :local_key_field => 'la_code'  , :local_table => 'rets_agents'       , :date_modified_field => 'LA_DATE_MODIFIED' })
      when 'OPH' then Caboose::StdClass.new({ :search_type => 'OpenHouse' , :remote_key_field => 'ID'         , :local_key_field => 'id'       , :local_table => 'rets_open_houses'  , :date_modified_field => 'DATE_MODIFIED'    })
      when 'GFX' then Caboose::StdClass.new({ :search_type => 'Media'     , :remote_key_field => 'MEDIA_ID'   , :local_key_field => 'media_id' , :local_table => 'rets_media'        , :date_modified_field => 'DATE_MODIFIED'    })
    end
  end

  #=============================================================================
  # Import method
  #=============================================================================

  def self.import(class_type, query)    
    m = self.meta(class_type)
    #self.log("Importing #{m.search_type}:#{class_type} with query #{query}...")
    self.get_config if @@config.nil? || @@config['url'].nil?
    params = {
      :search_type => m.search_type,
      :class => class_type,
      :query => query,
      :limit => -1,
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
      when 'OPH' then CabooseRets::OpenHouse
      when 'GFX' then CabooseRets::Media
      when 'COM' then CabooseRets::CommercialProperty
      when 'LND' then CabooseRets::LandProperty
      when 'MUL' then CabooseRets::MultiFamilyProperty
      when 'RES' then CabooseRets::ResidentialProperty
      when 'AGT' then CabooseRets::Agent
      when 'OFF' then CabooseRets::Office
    end
    obj = case class_type
      when 'OPH' then m.where(:id       => data['ID'].to_i       ).exists? ? m.where(:id       => data['ID'].to_i       ).first : m.new(:id       => data['ID'].to_i       )
      when 'GFX' then m.where(:media_id => data['MEDIA_ID']      ).exists? ? m.where(:media_id => data['MEDIA_ID']      ).first : m.new(:media_id => data['MEDIA_ID']      )
      when 'COM' then m.where(:id       => data['MLS_ACCT'].to_i ).exists? ? m.where(:id       => data['MLS_ACCT'].to_i ).first : m.new(:id       => data['MLS_ACCT'].to_i )
      when 'LND' then m.where(:id       => data['MLS_ACCT'].to_i ).exists? ? m.where(:id       => data['MLS_ACCT'].to_i ).first : m.new(:id       => data['MLS_ACCT'].to_i )
      when 'MUL' then m.where(:id       => data['MLS_ACCT'].to_i ).exists? ? m.where(:id       => data['MLS_ACCT'].to_i ).first : m.new(:id       => data['MLS_ACCT'].to_i )
      when 'RES' then m.where(:id       => data['MLS_ACCT'].to_i ).exists? ? m.where(:id       => data['MLS_ACCT'].to_i ).first : m.new(:id       => data['MLS_ACCT'].to_i )
      when 'AGT' then m.where(:la_code  => data['LA_LA_CODE']    ).exists? ? m.where(:la_code  => data['LA_LA_CODE']    ).first : m.new(:la_code  => data['LA_LA_CODE']    )
      when 'OFF' then m.where(:lo_code  => data['LO_LO_CODE']    ).exists? ? m.where(:lo_code  => data['LO_LO_CODE']    ).first : m.new(:lo_code  => data['LO_LO_CODE']    )
    end
    return obj
  end

  #=============================================================================
  # Main updater
  #=============================================================================

  def self.update_after(date_modified, save_images = true)
    self.delay.update_helper('RES', date_modified, save_images)
    self.delay.update_helper('COM', date_modified, save_images)
    self.delay.update_helper('LND', date_modified, save_images)
    self.delay.update_helper('MUL', date_modified, save_images)
    self.delay.update_helper('OFF', date_modified, save_images)
    self.delay.update_helper('AGT', date_modified, save_images)
    self.delay.update_helper('OPH', date_modified, save_images)
  end

  def self.update_helper(class_type, date_modified, save_images = true)
    m = self.meta(class_type)
    k = m.remote_key_field    
    d = date_modified.in_time_zone(CabooseRets::timezone).strftime("%FT%T")    
    params = {
      :search_type => m.search_type,
      :class => class_type,
      :select => [m.remote_key_field],
      :query => "(#{m.date_modified_field}=#{d}+)",
      :standard_names_only => true,
      :timeout => -1
    }
    self.client.search(params) do |data|
      case class_type
        when 'RES' then self.delay(:priority => 10).import_residential_property(  data[k], save_images)
        when 'COM' then self.delay(:priority => 10).import_commercial_property(   data[k], save_images)
        when 'LND' then self.delay(:priority => 10).import_land_property(         data[k], save_images)
        when 'MUL' then self.delay(:priority => 10).import_multi_family_property( data[k], save_images)
        when 'OFF' then self.delay(:priority => 10).import_office(                data[k], save_images)
        when 'AGT' then self.delay(:priority => 10).import_agent(                 data[k], save_images)
        when 'OPH' then self.delay(:priority => 10).import_open_house(            data[k], save_images)
      end
    end
  end

  #=============================================================================
  # Single model import methods (called from a worker dyno)
  #=============================================================================

  def self.import_property(mls_acct, save_images = true)
    self.import('RES', "(MLS_ACCT=*#{mls_acct}*)")
    p = CabooseRets::ResidentialProperty.where(:id => mls_acct.to_i).first
    if p.nil?
      self.import('COM', "(MLS_ACCT=*#{mls_acct}*)")
      p = CabooseRets::CommercialProperty.where(:id => mls_acct.to_i).first
      if p.nil?
        self.import('LND', "(MLS_ACCT=*#{mls_acct}*)")
        p = CabooseRets::LandProperty.where(:id => mls_acct.to_i).first
        if p.nil?
          self.import('MUL', "(MLS_ACCT=*#{mls_acct}*)")
          p = CabooseRets::MultiFamilyProperty.where(:id => mls_acct.to_i).first
          return if p.nil?
        end
      end
    end
    self.download_property_images(p, save_images)
  end

  def self.import_residential_property(mls_acct, save_images = true)
    self.import('RES', "(MLS_ACCT=*#{mls_acct}*)")
    p = CabooseRets::ResidentialProperty.where(:id => mls_acct.to_i).first
    self.download_property_images(p, save_images)
    self.update_coords(p)
  end

  def self.import_commercial_property(mls_acct, save_images = true)
    self.import('COM', "(MLS_ACCT=*#{mls_acct}*)")
    p = CabooseRets::CommercialProperty.where(:id => mls_acct.to_i).first
    self.download_property_images(p, save_images)
    self.update_coords(p)
  end

  def self.import_land_property(mls_acct, save_images = true)
    self.import('LND', "(MLS_ACCT=*#{mls_acct}*)")
    p = CabooseRets::LandProperty.where(:id => mls_acct.to_i).first
    self.download_property_images(p, save_images)
    self.update_coords(p)
  end

  def self.import_multi_family_property(mls_acct, save_images = true)
    self.import('MUL', "(MLS_ACCT=*#{mls_acct}*)")
    p = CabooseRets::MultiFamilyProperty.where(:id => mls_acct.to_i).first
    self.download_property_images(p, save_images)
    self.update_coords(p)
  end

  def self.import_office(lo_code, save_images = true)    
    self.import('OFF', "(LO_LO_CODE=*#{lo_code}*)")
    office = CabooseRets::Office.where(:lo_code => lo_code.to_s).first
    self.download_office_image(office) if save_images == true
  end

  def self.import_agent(la_code, save_images = true)
    self.import('AGT', "(LA_LA_CODE=*#{la_code}*)")
    a = CabooseRets::Agent.where(:la_code => la_code.to_s).first
    self.download_agent_image(a) #if save_images == true
  end

  def self.import_open_house(id, save_images = true)
    self.import('OPH', "((ID=#{id}+),(ID=#{id}-))")
  end

  def self.import_media(id, save_images = true)
    self.import('GFX', "((MEDIA_ID=#{id}+),(MEDIA_ID=#{id}-))")        
  end

  #=============================================================================
  # Images
  #=============================================================================
    
  def self.download_property_images(p, save_images = true)
    return if save_images == false
    
    self.log("- Downloading GFX records for #{p.mls_acct}...")
    params = {
      :search_type => 'Media',
      :class => 'GFX',      
      :query => "(MLS_ACCT=*#{p.mls_acct}*)",
      :timeout => -1
    }
    ids = []
    self.client.search(params) do |data|
      ids << data['MEDIA_ID']      
      m = CabooseRets::Media.where(:media_id => data['MEDIA_ID']).first
      m = CabooseRets::Media.new if m.nil?             
      m.parse(data)      
      m.save
    end
    
    if ids.count > 0
      # Delete any records in the local database that shouldn't be there    
      self.log("- Deleting GFX records for MLS ##{p.mls_acct} in the local database that are not in the remote database...")
      query = "select media_id from rets_media where mls_acct = '#{p.mls_acct}'"
      rows = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql_array, query))
      local_ids = rows.collect{ |row| row['media_id'] }
      ids_to_remove = local_ids - ids
      if ids_to_remove && ids_to_remove.count > 0
        query = ["delete from rets_media where media_id in (?)", ids_to_remove]
        ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, query))
      end
    end
        
  end
  
  def self.download_agent_image(agent)
    self.log "Saving image for #{agent.first_name} #{agent.last_name}..."
    begin
      self.client.get_object(:resource => :Agent, :type => :Photo, :location => true, :id => agent.la_code) do |headers, content|                
        agent.image_location = headers['location']
        agent.save
      end
    rescue RETS::APIError => err
      self.log "No image for #{agent.first_name} #{agent.last_name}."
      self.log err
    end
  end

  #=============================================================================
  # GPS
  #=============================================================================

  def self.update_coords(p = nil)
    if p.nil?
      models = [CabooseRets::CommercialProperty, CabooseRets::LandProperty, CabooseRets::MultiFamilyProperty, CabooseRets::ResidentialProperty]
      names = ["commercial", "land", "multi-family", "residential"]
      i = 0
      models.each do |model|
        self.log "Updating coords #{names[i]} properties..."
        model.where(:latitude => nil).reorder(:mls_acct).each do |p|
          self.update_coords(p)
        end
        i = i + 1
      end
      return
    end

    self.log "Getting coords for mls_acct #{p.mls_acct}..."
    coords = self.coords_from_address(CGI::escape "#{p.street_num} #{p.street_name}, #{p.city}, #{p.state} #{p.zip}")
    if coords.nil? || coords == false
      self.log "Can't set coords for mls acct #{p.mls_acct}..."
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
    self.purge_residential
    self.purge_commercial
    self.purge_land
    self.purge_multi_family
    self.purge_offices
    #self.purge_agents
    self.purge_open_houses
    self.purge_media
  end

  def self.purge_residential()  self.delay.purge_helper('RES', '2012-01-01') end
  def self.purge_commercial()   self.delay.purge_helper('COM', '2012-01-01') end
  def self.purge_land()         self.delay.purge_helper('LND', '2012-01-01') end
  def self.purge_multi_family() self.delay.purge_helper('MUL', '2012-01-01') end
  def self.purge_offices()      self.delay.purge_helper('OFF', '2012-01-01') end
  def self.purge_agents()       self.delay.purge_helper('AGT', '2012-01-01') end
  def self.purge_open_houses()  self.delay.purge_helper('OPH', '2012-01-01') end
  def self.purge_media()        self.delay.purge_helper('GFX', '2012-01-01') end

  def self.purge_helper(class_type, date_modified)
    m = self.meta(class_type)

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
    self.client.search(params.merge({ :count_mode => :only }))
    count = self.client.rets_data[:code] == "20201" ? 0 : self.client.rets_data[:count]
    batch_count = (count.to_f/5000.0).ceil
    
    ids = []
    k = m.remote_key_field
    (0...batch_count).each do |i|
      self.log("- Getting ids for #{class_type} (batch #{i+1} of #{batch_count})...")
      self.client.search(params.merge({ :select => [k], :limit => 5000, :offset => 5000*i })) do |data|                
        ids << (class_type == 'OPH' ? data[k].to_i : data[k])        
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
          when 'RES' then self.delay.import_residential_property(id, false)
          when 'COM' then self.delay.import_commercial_property(id, false)
          when 'LND' then self.delay.import_land_property(id, false)
          when 'MUL' then self.delay.import_multi_family_property(id, false)
          when 'OFF' then self.delay.import_office(id, false)
          when 'AGT' then self.delay.import_agent(id, false)
          when 'OPH' then self.delay.import_open_house(id, false)
          when 'GFX' then self.delay.import_media(id, false)
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
      :query => "(#{m.date_modified_field}=#{date_modified}T00:00:01+)",
      :standard_names_only => true,
      :timeout => -1
    }
    self.client.search(params.merge({ :count_mode => :only }))
    count = self.client.rets_data[:code] == "20201" ? 0 : self.client.rets_data[:count]
    batch_count = (count.to_f/5000.0).ceil

    ids = []
    k = m.remote_key_field
    (0...batch_count).each do |i|
      self.client.search(params.merge({ :select => [k], :limit => 5000, :offset => 5000*i })) do |data|
        ids << case class_type
          when 'RES' then data[k] 
          when 'COM' then data[k] 
          when 'LND' then data[k] 
          when 'MUL' then data[k] 
          when 'OFF' then data[k]  
          when 'AGT' then data[k]
          when 'OPH' then data[k].to_i
          when 'GFX' then data[k]
        end                
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
          when 'RES' then self.delay.import_residential_property(id, false)
          when 'COM' then self.delay.import_commercial_property(id, false)
          when 'LND' then self.delay.import_land_property(id, false)
          when 'MUL' then self.delay.import_multi_family_property(id, false)
          when 'OFF' then self.delay.import_office(id, false)
          when 'AGT' then self.delay.import_agent(id, false)
          when 'OPH' then self.delay.import_open_house(id, false)
          when 'GFX' then self.delay.import_media(id)
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
		self.log2("Adding the update rets task for 5 minutes from now...")
		q = "handler like '%update_rets%'"
		count = Delayed::Job.where(q).count		 
		if count == 0 || (count == 1 && Delayed::Job.where(q).first.locked_at)
		  self.delay(:run_at => 5.minutes.from_now).update_rets
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