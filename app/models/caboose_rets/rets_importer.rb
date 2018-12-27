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
      when 'Office'    then Caboose::StdClass.new({ :search_type => 'Office'    , :remote_key_field => 'OfficeMlsId' , :local_key_field => 'lo_mls_id'    , :local_table => 'rets_offices'      , :date_modified_field => 'ModificationTimestamp'})
      when 'Member'    then Caboose::StdClass.new({ :search_type => 'Member'    , :remote_key_field => 'MemberMlsId' , :local_key_field => 'mls_id'    , :local_table => 'rets_agents'       , :date_modified_field => 'ModificationTimestamp'})
      when 'OpenHouse' then Caboose::StdClass.new({ :search_type => 'OpenHouse' , :remote_key_field => 'OpenHouseKey' , :local_key_field => 'matrix_unique_id'    , :local_table => 'rets_open_houses'  , :date_modified_field => 'ModificationTimestamp'})
      when 'Property'  then Caboose::StdClass.new({ :search_type => 'Property'  , :remote_key_field => 'ListingId' , :local_key_field => 'mls_number'    , :local_table => 'rets_properties'   , :date_modified_field => 'ModificationTimestamp'})
      when 'Media'     then Caboose::StdClass.new({ :search_type => 'Media'     , :remote_key_field => 'MediaObjectID'         , :local_key_field => 'media_id'            , :local_table => 'rets_media'        , :date_modified_field => 'ModificationTimestamp'   })
      end
  end

  #=============================================================================
  # Import method
  #=============================================================================

  def self.import(class_type, query)
    m = self.meta(class_type)
    self.log3(class_type,nil,"Importing #{m.search_type}:#{class_type} with query #{query}...") 
    self.get_config if @@config.nil? || @@config['url'].nil?
    params = {
      :search_type => m.search_type,
      :class => class_type,
      :query => query,
    #  :limit => 3,
      :timeout => -1
    }
    obj = nil

    begin
      self.client.search(params) do |data|
        obj = self.get_instance_with_id(class_type, data)
        if obj.nil?
          self.log3(class_type,nil,"Error: object is nil")
          self.log3(class_type,nil,data.inspect)
          next
        end
        obj.parse(data)
        obj.save
      end
    rescue RETS::HTTPError => err
      self.log3(class_type,nil,"Import error for #{class_type}: #{query}")
      self.log3(class_type,nil,err.message)
    end
  end

  def self.get_instance_with_id(class_type, data)
    obj = nil
    self.log "Getting instance of #{class_type}..."
    m = case class_type
      when 'Property'  then CabooseRets::Property
      when 'OpenHouse' then CabooseRets::OpenHouse
      when 'Member'    then CabooseRets::Agent
      when 'Office'    then CabooseRets::Office
      when 'Media'     then CabooseRets::Media
    end  
    obj  = case class_type
      when 'Property'  then m.where(:mls_number => data['ListingId']).exists? ? m.where(:mls_number => data['ListingId']).first : m.create(:mls_number => data['ListingId'])
      when 'OpenHouse' then m.where(:matrix_unique_id => data['OpenHouseKey']).exists? ? m.where(:matrix_unique_id => data['OpenHouseKey']).first : m.create(:matrix_unique_id => data['OpenHouseKey'])
      when 'Member'    then m.where(:mls_id => data['MemberMlsId']).exists? ? m.where(:mls_id => data['MemberMlsId']).first : m.create(:mls_id => data['MemberMlsId'])
      when 'Office'    then m.where(:lo_mls_id => data['OfficeMlsId']).exists? ? m.where(:lo_mls_id => data['OfficeMlsId']).first : m.create(:lo_mls_id => data['OfficeMlsId'])
      when 'Media'     then m.where(:media_id => data['MediaObjectID']      ).exists? ? m.where(:media_id => data['MediaObjectID']      ).first : m.create(:media_id => data['MediaObjectID']      )
    end
    self.log "Found matching object ID #{obj.id}"
    return obj
  end

  #=============================================================================
  # Main updater
  #=============================================================================

  def self.update_after(date_modified, save_images = true)
    si = save_images ? 'saving images' : 'not saving images'
    self.log3(nil,nil,"Updating everything after #{date_modified} and #{si}")
    self.delay(:priority => 10, :queue => 'rets').update_helper('Property' , date_modified, save_images)
    self.delay(:priority => 10, :queue => 'rets').update_helper('Office'   , date_modified, false)
    self.delay(:priority => 10, :queue => 'rets').update_helper('Member'   , date_modified, false)
    self.delay(:priority => 10, :queue => 'rets').update_helper('OpenHouse', date_modified, false)
  end

  def self.update_helper(class_type, date_modified, save_images = true)
    si = save_images ? 'saving images' : 'not saving images'
    self.log3(class_type,nil,"Updating #{class_type} modified after #{date_modified} and #{si}")
    m = self.meta(class_type)
    k = m.remote_key_field
    d = date_modified.in_time_zone(CabooseRets::timezone).strftime("%FT%T")
    quer = "(#{m.date_modified_field}=#{d}+)"
    params = {
      :search_type => m.search_type,
      :class => class_type,
      :select => [m.remote_key_field],
      :querytype => 'DMQL2',
      :query => quer,
      :standard_names_only => true,
      :timeout => -1
    }    
    self.log3(class_type,nil,"Searching with params: " + params.to_s)
    self.client.search(params) do |data|
      self.log3(class_type,nil,"Resulting data: " + data.to_s)
      case class_type
        when 'Property'  then self.delay(:priority => 10, :queue => 'rets').import_properties(data[k], save_images)
        when 'Office'    then self.delay(:priority => 10, :queue => 'rets').import_office(    data[k], false)
        when 'Member'    then self.delay(:priority => 10, :queue => 'rets').import_agent(     data[k], false)
        when 'OpenHouse' then self.delay(:priority => 10, :queue => 'rets').import_open_house(data[k], false)
      end
    end

    # Check for changed images 
    if class_type == 'Property'
      self.log3("Property",nil,"Checking for modified images on Properties...")
      d1 = (self.last_updated - 1.hours).in_time_zone(CabooseRets::timezone).strftime("%FT%T")
      params = {
        :search_type => m.search_type,
        :class => class_type,
        :select => [m.remote_key_field],
        :querytype => 'DMQL2',
        :query => "(PhotosChangeTimestamp=#{d1}+)",
        :standard_names_only => true,
        :timeout => -1
      }
      self.log3(class_type,nil,"Searching with params: " + params.to_s)
      self.client.search(params) do |data|
        self.log3(class_type,nil,"Resulting data: " + data.to_s)
        self.delay(:priority => 10, :queue => 'rets').import_properties(data[k], true)
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

  def self.import_properties(mls_id, save_images = true)
    si = save_images ? 'saving images' : 'not saving images'
    self.log3('Property',mls_id,"Importing Property #{mls_id} and #{si}...")
    save_images = true if !CabooseRets::Property.where(:mls_number => mls_id.to_s).exists?
    self.import('Property', "(ListingId=#{mls_id})")
    p = CabooseRets::Property.where(:mls_number => mls_id.to_s).first
    if p != nil
      self.download_property_images(p) if save_images
      self.update_coords(p) if p.latitude.blank? || p.longitude.blank?
    else
      self.log3(nil,nil,"No Property associated with #{mls_id}")
    end
  end

  def self.import_office(mls_id, save_images = true)
    self.log3('Office',mls_id,"Importing Office #{mls_id}...")
    self.import('Office', "(OfficeMlsId=#{mls_id})")
    office = CabooseRets::Office.where(:matrix_unique_id => mls_id.to_s).first
  end

  def self.import_agent(mls_id, save_images = true)
    self.log3('Agent',mls_id,"Importing Agent #{mls_id}...")
    self.import('Member', "(MemberMlsId=#{mls_id})")
    a = CabooseRets::Agent.where(:mls_id => mls_id.to_s).first
  end

  def self.import_open_house(oh_id, save_images = true)
    self.log3('OpenHouse',oh_id,"Importing Open House #{oh_id}...")
    self.import('OpenHouse', "(OpenHouseKey=#{oh_id})")
  end

  def self.import_media(id, save_images = true)
    self.log3('Media',id,"Importing Media #{id}...")
    self.import('Media', "((MediaObjectID=#{id}+),(MediaObjectID=#{id}-))")
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
    self.log3('Property',p.mls_number,"Downloading images for #{p.mls_number}...")
    begin
      # Get first image
      self.client.get_object(:resource => 'Property', :type => 'Photo', :location=> false, :id => "#{p.matrix_unique_id}:0") do |headers, content|
        m = CabooseRets::Media.where(:media_mui => headers['content-id'], :media_order => 0).first
        m = CabooseRets::Media.new if m.nil?
        tmp_path = "#{Rails.root}/tmp/rets_media_#{headers['content-id']}:0.jpeg"
        File.open(tmp_path, "wb") do |f|
          f.write(content)
        end
        m.media_mui     = headers['content-id']
        m.media_order   = 0
        m.media_type    = 'Photo'
        cm               = Caboose::Media.new
        cm.image         = File.open(tmp_path)
        cm.name          = "rets_media_#{headers['content-id']}_0"
        cm.original_name = "rets_media_#{headers['content-id']}_0.jpeg"
        cm.processed     = true
        cm.save
        m.media_id = cm.id
        m.save
        `rm #{tmp_path}`
        self.log("Image rets_media_#{headers['content-id']}_0 saved")
      end
      # Get rest of images
      self.client.get_object(:resource => 'Property', :type => 'Photo', :location=> false, :id => "#{p.matrix_unique_id}:*") do |headers, content|
        m = CabooseRets::Media.where(:media_mui => headers['content-id'], :media_order => headers['orderhint']).first
        m = CabooseRets::Media.new if m.nil?
        tmp_path = "#{Rails.root}/tmp/rets_media_#{headers['content-id']}:#{headers['object-id']}.jpeg"
        File.open(tmp_path, "wb") do |f|
          f.write(content)
        end
        m.media_mui     = headers['content-id']
        m.media_order   = headers['orderhint']
        m.media_type    = 'Photo'
        cm               = Caboose::Media.new
        cm.image         = File.open(tmp_path)
        cm.name          = "rets_media_#{headers['content-id']}_#{headers['object-id']}"
        cm.original_name = "rets_media_#{headers['content-id']}_#{headers['object-id']}.jpeg"
        cm.processed     = true
        cm.save
        m.media_id = cm.id
        m.save
        `rm #{tmp_path}`
        self.log("Image rets_media_#{headers['content-id']}_#{headers['object-id']} saved")
      end
    rescue RETS::APIError => err
      self.log "No image for #{p.mls_number}."
      self.log err
    end
  end

  def self.download_missing_images
    self.log3("Property",nil,"Downloading all missing images...")
    CabooseRets::Property.where("photo_count = ? OR photo_count is null", '').all.each do |p|
      self.delay(:priority => 10, :queue => 'rets').import_properties(p.mls_number, true)
    end
  end

  def self.download_agent_image(agent)
    # self.log "Saving image  for #{agent.first_name} #{agent.last_name}..."
    # begin
    #   self.client.get_object(:resource => :Member, :type => :Photo, :location => true, :id => property.list_agent_mls_id) do |headers, content|
    #     agent.verify_meta_exists
    #     agent.meta.image_location = headers['location']
    #     agent.meta.save
    #   end
    # rescue RETS::APIError => err
    #   self.log "No image for #{agent.first_name} #{agent.last_name}."
    #   self.log err
    # end
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
        self.log3('Property',nil,"Updating coords properties...")
        model.where(:latitude => nil).reorder(:mls_number).each do |p1|
          self.delay(:priority => 10, :queue => 'rets').update_coords(p1)
        end
      return
    end

    self.log3('Property',p.mls_number,"Getting coords for MLS # #{p.mls_number}...")
    coords = self.coords_from_address(CGI::escape "#{p.street_number} #{p.street_name}, #{p.city}, #{p.state_or_province} #{p.postal_code}")
    if coords.nil? || coords == false
      self.log3('Property',nil,"Can't set coords for MLS # #{p.mls_number}...")
      return
    end

    p.latitude = coords['lat']
    p.longitude = coords['lng']
    p.save
  end

  def self.coords_from_address(address)
    begin
      uri = "https://maps.googleapis.com/maps/api/geocode/json?key=AIzaSyBD34Da5DhRH5wkq3sROsE7-jv90-f1v6o&address=#{address}"
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
    self.log3(nil,nil,'purging')
    self.purge_properties
    self.purge_offices
    self.purge_agents
    self.purge_open_houses
  end  
  
  def self.purge_properties()   self.delay(:priority => 10, :queue => 'rets').purge_helper('Property', '2012-01-01') end
  def self.purge_offices()      self.delay(:priority => 10, :queue => 'rets').purge_helper('Office', '2012-01-01') end
  def self.purge_agents()       self.delay(:priority => 10, :queue => 'rets').purge_helper('Member', '2012-01-01') end
  def self.purge_open_houses()  self.delay(:priority => 10, :queue => 'rets').purge_helper('OpenHouse', '2012-01-01') end
  

  def self.purge_helper(class_type, date_modified)    
    m = self.meta(class_type)    
    self.log(m.search_type)

    self.log3(class_type,nil,"Purging #{class_type}...")

    # Get the total number of records
    self.log3(class_type,nil,"Getting total number of records for #{class_type}...")

    statusquery = ""

    case class_type
      when 'Property'  then statusquery = "MlsStatus=Active"
      when 'Office'    then statusquery = "OfficeStatus=Active"
      when 'Member'    then statusquery = "MemberStatus=Active"
      when 'OpenHouse' then statusquery = "OpenHouseKeyNumeric=0+"
    end

    params = {
      :search_type => m.search_type,
      :class => class_type,
      :query => "(#{m.date_modified_field}=#{date_modified}T00:00:01+)AND(#{statusquery})",
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
      self.log3(class_type,nil,"Getting ids for #{class_type} (batch #{i+1} of #{batch_count})...")
      self.client.search(params.merge({ :select => [k], :limit => 5000, :offset => 5000*i })) do |data|
        ids << data[k]
      end
    end

    # Only do stuff if we got a real response from the server
    if ids.count > 0

      self.log3(class_type,nil,"Remote IDs found: #{ids.to_s}")

      # Delete any records in the local database that shouldn't be there
      self.log3(class_type,nil,"Finding #{class_type} records in the local database that are not in the remote database...")
      t = m.local_table
      k = m.local_key_field
      query = "select distinct #{k} from #{t}"
      rows = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql_array, query))
      local_ids = rows.collect{ |row| row[k] }
      self.log3(class_type,nil,"Local IDs found: #{local_ids.to_s}")
      ids_to_remove = local_ids - ids
      self.log3(class_type,nil,"Found #{ids_to_remove.count} #{class_type} records in the local database that are not in the remote database.")
      self.log3(class_type,nil,"Deleting #{class_type} records in the local database that shouldn't be there...")
      query = ["delete from #{t} where #{k} in (?)", ids_to_remove]
      ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, query))

      # Find any ids in the remote database that should be in the local database
      self.log3(class_type,nil,"Finding #{class_type} records in the remote database that should be in the local database...")
      query = "select distinct #{k} from #{t}"
      rows = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql_array, query))
      local_ids = rows.collect{ |row| row[k] }
      self.log3(class_type,nil,"Local IDs found: #{local_ids.to_s}")
      ids_to_add = ids - local_ids
      ids_to_add = ids_to_add.sort.reverse
      self.log3(class_type,nil,"Found #{ids_to_add.count} #{class_type} records in the remote database that we need to add to the local database.")
      ids_to_add.each do |id|
        self.log3(class_type,nil,"Importing #{id}...")
        case class_type
          when "Property"   then self.delay(:priority => 10, :queue => 'rets').import_properties(id, true)
          when "Office"    then self.delay(:priority => 10, :queue => 'rets').import_office(id, false)
          when "Member"     then self.delay(:priority => 10, :queue => 'rets').import_agent(id, false)
          when "OpenHouse" then self.delay(:priority => 10, :queue => 'rets').import_open_house(id, false)
        end
      end
    end
  end

  # def self.get_media_urls
  #   m = self.meta(class_type)

  #   # Get the total number of records
  #   params = {
  #     :search_type => m.search_type,
  #     :class => class_type,
  #     :query => "(#{m.matrix_modified_dt}=#{date_modified}T00:00:01+)",
  #     :standard_names_only => true,
  #     :timeout => -1
  #   }
  #   self.client.search(params.merge({ :count => 1 }))
  #   count = self.client.rets_data[:code] == "20201" ? 0 : self.client.rets_data[:count]
  #   batch_count = (count.to_f/5000.0).ceil

  #   ids = []
  #   k = m.remote_key_field
  #   (0...batch_count).each do |i|
  #     self.client.search(params.merge({ :select => [k], :limit => 5000, :offset => 5000*i })) do |data|
  #       ids << data[k]
  #     end
  #   end

  #   if ids.count > 0
  #     # Delete any records in the local database that shouldn't be there
  #     t = m.local_table
  #     k = m.local_key_field
  #     query = ["delete from #{t} where #{k} not in (?)", ids]
  #     ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, query))

  #     # Find any ids in the remote database that should be in the local database
  #     query = "select distinct #{k} from #{t}"      
  #     rows = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql_array, query))
  #     local_ids = rows.collect{ |row| row[k] }
  #     ids_to_add = ids - local_ids
  #     ids_to_add.each do |id|
  #       self.log("Importing #{id}...")
  #       case class_type
  #         when "Property"  then self.delay(:priority => 10, :queue => 'rets').import_properties(id, true)
  #         when "Office"    then self.delay(:priority => 10, :queue => 'rets').import_office(id, false)
  #         when "Member"    then self.delay(:priority => 10, :queue => 'rets').import_agent(id, false)
  #         when "OpenHouse" then self.delay(:priority => 10, :queue => 'rets').import_open_house(id, false)
  #       end
  #     end
  #   end

  # end

  #=============================================================================
  # Logging
  #=============================================================================

  def self.log(msg)
    puts "[rets_importer] #{msg}"
  end

  def self.log2(msg)
    puts "======================================================================"
    puts "[rets_importer] #{msg}"
    puts "======================================================================"
  end

  def self.log3(class_name, object_id, text)
    self.log2(text)
    log = CabooseRets::Log.new
    log.class_name = class_name
    log.object_id = object_id
    log.text = text
    log.timestamp = DateTime.now
    log.save
  end

  #=============================================================================
  # Locking update task
  #=============================================================================

  def self.update_rets
    self.log3(nil,nil,"Updating rets...")
    if self.task_is_locked
      self.log2("Task is locked, aborting.")
      return
    end
    self.log2("Locking task...")
    task_started = self.lock_task

    begin
      overlap = 2.hours
      if (DateTime.now - self.last_purged).to_f >= 0.5
        self.purge
        self.save_last_purged(task_started)
        overlap = 1.week
      end
      self.update_after((self.last_updated - overlap), false)
      self.download_missing_images
      self.log3(nil,nil,"Saving the timestamp for when we updated to #{task_started.to_s}...")
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

		# Start the same update process in 20 minutes
		self.log3(nil,nil,"Adding the update rets task for 20 minutes from now...")
		q = "handler like '%update_rets%'"
		count = Delayed::Job.where(q).count
		if count == 0 || (count == 1 && Delayed::Job.where(q).first.locked_at)
		  self.delay(:run_at => 20.minutes.from_now, :priority => 10, :queue => 'rets').update_rets
		end
    # Delete old logs
    CabooseRets::Log.where("timestamp < ?",(DateTime.now - 30.days)).destroy_all
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
