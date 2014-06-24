require 'ruby-rets'
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
        
    if (@@rets_client.nil?)     
      @@rets_client = RETS::Client.login(
        :url      => @@config['url'],
        :username => @@config['username'],
        :password => @@config['password']
      )
    end
    return @@rets_client
  end
  
  #=============================================================================
  # Import method
  #=============================================================================
  
  def self.import(query, search_type, class_type)
    self.log("Importing #{search_type}:#{class_type} with query #{query}...")    
    self.get_config if @@config.nil? || @@config['url'].nil?
    params = {
      :search_type => search_type,
      :class => class_type,
      :query => query,
      :limit => -1,      
      :timeout => -1
    }
    obj = nil
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

  def self.update_after(date_modified)
    self.update_residential_properties_modified_after(date_modified)  
    self.update_commercial_properties_modified_after(date_modified)  
    self.update_land_properties_modified_after(date_modified)
    self.update_multi_family_properties_modified_after(date_modified)
    self.update_offices_modified_after(date_modified)
    self.update_agents_modified_after(date_modified)
    self.update_open_houses_modified_after(date_modified)
  end                       
  def self.update_residential_properties_modified_after(date_modified)  self.client.search({ :search_type => 'Property' , :class => 'RES', :select => ['MLS_ACCT']   , :query => "(DATE_MODIFIED=#{date_modified.strftime("%FT%T")}+)"   , :standard_names_only => true, :timeout => -1 }) { |data| self.delay.import_residential_property  data['MLS_ACCT'  ] } end          
  def self.update_commercial_properties_modified_after(date_modified)   self.client.search({ :search_type => 'Property' , :class => 'COM', :select => ['MLS_ACCT']   , :query => "(DATE_MODIFIED=#{date_modified.strftime("%FT%T")}+)"   , :standard_names_only => true, :timeout => -1 }) { |data| self.delay.import_commercial_property   data['MLS_ACCT'  ] } end          
  def self.update_land_properties_modified_after(date_modified)         self.client.search({ :search_type => 'Property' , :class => 'LND', :select => ['MLS_ACCT']   , :query => "(DATE_MODIFIED=#{date_modified.strftime("%FT%T")}+)"   , :standard_names_only => true, :timeout => -1 }) { |data| self.delay.import_land_property         data['MLS_ACCT'  ] } end          
  def self.update_multi_family_properties_modified_after(date_modified) self.client.search({ :search_type => 'Property' , :class => 'MUL', :select => ['MLS_ACCT']   , :query => "(DATE_MODIFIED=#{date_modified.strftime("%FT%T")}+)"   , :standard_names_only => true, :timeout => -1 }) { |data| self.delay.import_multi_family_property data['MLS_ACCT'  ] } end
  def self.update_offices_modified_after(date_modified)                 self.client.search({ :search_type => 'Office'   , :class => 'OFF', :select => ['LO_LO_CODE'] , :query => "(LO_DATE_MODIFIED=#{date_modified.strftime("%FT%T")}+)", :standard_names_only => true, :timeout => -1 }) { |data| self.delay.import_office                data['LO_LO_CODE'] } end      
  def self.update_agents_modified_after(date_modified)                  self.client.search({ :search_type => 'Agent'    , :class => 'AGT', :select => ['LA_LA_CODE'] , :query => "(LA_DATE_MODIFIED=#{date_modified.strftime("%FT%T")}+)", :standard_names_only => true, :timeout => -1 }) { |data| self.delay.import_agent                 data['LA_LA_CODE'] } end     
  def self.update_open_houses_modified_after(date_modified)             self.client.search({ :search_type => 'OpenHouse', :class => 'OPH', :select => ['ID']         , :query => "(DATE_MODIFIED=#{date_modified.strftime("%FT%T")}+)"   , :standard_names_only => true, :timeout => -1 }) { |data| self.delay.import_open_house            data['ID'        ] } end
    
  #=============================================================================
  # Single model import methods (called from a worker dyno)
  #=============================================================================
  
  def self.import_property(mls_acct)
    self.import("(MLS_ACCT=*#{mls_acct}*)", 'Property', 'RES')
    p = CabooseRets::ResidentialProperty.where(:id => mls_acct.to_i).first
    if p.nil?
      self.import("(MLS_ACCT=*#{mls_acct}*)", 'Property', 'COM')
      p = CabooseRets::CommercialProperty.where(:id => mls_acct.to_i).first      
      if p.nil?
        self.import("(MLS_ACCT=*#{mls_acct}*)", 'Property', 'LND')
        p = CabooseRets::LandProperty.where(:id => mls_acct.to_i).first
        if p.nil?
          self.import("(MLS_ACCT=*#{mls_acct}*)", 'Property', 'MUL')
          p = CabooseRets::MultiFamilyProperty.where(:id => mls_acct.to_i).first
          return if p.nil?
        end
      end
    end
    self.download_property_images(p)
  end
  
  def self.import_residential_property(mls_acct)    
    self.import("(MLS_ACCT=*#{mls_acct}*)", 'Property', 'RES')
    p = CabooseRets::ResidentialProperty.where(:id => mls_acct.to_i).first    
    self.download_property_images(p)    
    self.update_coords(p)        
  end
  
  def self.import_commercial_property(mls_acct)    
    self.import("(MLS_ACCT=*#{mls_acct}*)", 'Property', 'COM')
    p = CabooseRets::CommercialProperty.where(:id => mls_acct.to_i).first
    self.download_property_images(p)
    self.update_coords(p)
  end
  
  def self.import_land_property(mls_acct)    
    self.import("(MLS_ACCT=*#{mls_acct}*)", 'Property', 'LND')
    p = CabooseRets::LandProperty.where(:id => mls_acct.to_i).first    
    self.download_property_images(p)
    self.update_coords(p)
  end
  
  def self.import_multi_family_property(mls_acct)    
    self.import("(MLS_ACCT=*#{mls_acct}*)", 'Property', 'MUL')
    p = CabooseRets::MultiFamilyProperty.where(:id => mls_acct.to_i).first
    self.download_property_images(p)
    self.update_coords(p)
  end
  
  def self.import_office(lo_code)
    self.import("(LO_LO_CODE=*#{lo_code}*)", 'Office', 'OFF')
    office = CabooseRets::Office.where(:lo_code => lo_code.to_s).first
    self.download_office_image(office)
  end
  
  def self.import_agent(la_code)
    self.import("(LA_LA_CODE=*#{la_code}*)", 'Agent', 'AGT')
    a = CabooseRets::Agent.where(:la_code => la_code.to_s).first
    self.download_agent_image(a)
  end
  
  def self.import_open_house(id)
    self.import("(ID=*#{id}*)", 'OpenHouse', 'OPH')        
  end

  #=============================================================================
  # Images
  #=============================================================================
    
  def self.download_property_images(p)
    self.refresh_property_media(p)
    
    self.log("-- Downloading images and resizing for #{p.mls_acct}")
    media = []
    self.client.get_object(:resource => :Property, :type => :Photo, :location => true, :id => p.id) do |headers, content|
      
      # Find the associated media record for the image
      filename = File.basename(headers['location'])
      m = CabooseRets::Media.where(:mls_acct => p.mls_acct, :file_name => filename).first
      
      if m.nil?
        self.log("Can't find media record for #{p.mls_acct} #{filename}.")
      else         
        m.image = URI.parse(headers['location'])
        media << m
        #m.save
      end      
    end
    
    self.log("-- Uploading images to S3 for #{p.mls_acct}")
    media.each do |m|      
      m.save
    end        
  end
  
  def self.refresh_property_media(p)
    self.log("-- Deleting images and metadata for #{p.mls_acct}...")    
    #CabooseRets::Media.where(:mls_acct => p.mls_acct, :media_type => 'Photo').destroy_all
    CabooseRets::Media.where(:mls_acct => p.mls_acct).destroy_all
    
    self.log("-- Downloading image metadata for #{p.mls_acct}...")    
    params = {
      :search_type => 'Media',
      :class => 'GFX',
      #:query => "(MLS_ACCT=*#{p.id}*),(MEDIA_TYPE=|I)",
      :query => "(MLS_ACCT=*#{p.id}*)",
      :timeout => -1
    }    
    self.client.search(params) do |data|      
      m = CabooseRets::Media.new
      m.parse(data)
      #m.id = m.media_id
      m.save
    end
  end
  
  def self.download_agent_image(agent)            
    self.log "Saving image for #{agent.first_name} #{agent.last_name}..."
    begin
      self.client.get_object(:resource => :Agent, :type => :Photo, :location => true, :id => agent.la_code) do |headers, content|
        agent.image = URI.parse(headers['location'])
        agent.save
      end
    rescue RETS::APIError => err
      self.log "No image for #{agent.first_name} #{agent.last_name}."
    end    
  end
  
  def self.download_office_image(office)            
    self.log "Saving image for #{office.lo_name}..."
    begin
      self.client.get_object(:resource => :Office, :type => :Photo, :location => true, :id => office.lo_code) do |headers, content|
        office.image = URI.parse(headers['location'])
        office.save
      end
    rescue RETS::APIError => err      
      self.log "No image for #{office.lo_name}."
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
    return if coords.nil? || coords == false
    
    p.latitude = coords['lat']
    p.longitude = coords['lng']
    p.save    
  end
  
  def self.coords_from_address(address)   
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
  # Logging
  #=============================================================================
  
  def self.log(msg)
    #puts "[rets_importer] #{msg}"
    Rails.logger.info("[rets_importer] #{msg}")
  end  
  
  #=============================================================================
  # Locking update task
  #=============================================================================
  
  def self.last_updated
    if !Caboose::Setting.exists?(:name => 'rets_last_updated')
      Caboose::Setting.create(:name => 'rets_last_updated', :value => '2013-08-06T00:00:01')
    end
    s = Caboose::Setting.where(:name => 'rets_last_updated').first
    return DateTime.parse(s.value)
  end
  
  def self.save_last_updated(d)
    s = Caboose::Setting.where(:name => 'rets_last_updated').first
    s.value = d.strftime('%FT%T')
    s.save
  end
  
  def self.task_is_locked
    return Caboose::Setting.exists?(:name => 'rets_update_running')
  end
  
  def self.lock_task
    d = DateTime.now.utc - 5.hours
    Caboose::Setting.create(:name => 'rets_update_running', :value => d.strftime('%F %T'))
    return d
  end
  
  def self.unlock_task
    Caboose::Setting.where(:name => 'rets_update_running').first.destroy
  end
  
  def self.unlock_task_if_last_updated(d)
    setting = Caboose::Setting.where(:name => 'rets_update_running').first
    self.unlock_task if setting && d.strftime('%F %T') == setting.value
  end
  
end