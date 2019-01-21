require "rets/version"
require "rets/exceptions"
require "rets/client"
require "rets/http"
require "rets/stream_http"
require "rets/base/core"
require "rets/base/sax_search"
require "rets/base/sax_metadata"
require "caboose_rets/version"

namespace :caboose_rets do

  desc "Do a simple search"
  task :simple_search => :environment do
    type = ['p','a','o','oh']
    @@config = {
      'url'                 => nil,
      'username'            => nil,
      'password'            => nil,
      'temp_path'           => nil,
      'log_file'            => nil,
      'media_base_url'      => nil
    }
    config = YAML::load(File.open("#{Rails.root}/config/rets_importer.yml"))    
    config = config[Rails.env]
    config.each { |key,val| @@config[key] = val }
    client = RETS::Client.login(
      :url      => config['url'],
      :username => config['username'],
      :password => config['password']
    )
    type.each do |t|
      if t == 'p'
        params = {
          :search_type => 'Property',
          :class       => 'Property',
          :query       => "(MlsStatus=Active)AND(OriginatingSystemName=WESTAL)",
          :limit       => 1,
          :timeout     => -1
        }
      elsif t == 'a'      
        params = {
          :search_type => 'Member',
          :class       => 'Member',
          :query       => "(MemberStatus=Active)AND(OriginatingSystemName=WESTAL)",
          :limit       => 1,
          :timeout     => -1
        }
      elsif t == 'o'                
        params = {
          :search_type => 'Office',
          :class       => 'Office',
          :query       => "(OfficeStatus=Active)AND(OriginatingSystemName=WESTAL)",
          :limit       => 1,
          :timeout     => -1
        }
      elsif t == 'oh'       
        params = {
          :search_type => 'OpenHouse',
          :class       => 'OpenHouse',
          :query       => "(OpenHouseKeyNumeric=0+)AND(OriginatingSystemName=WESTAL)",
          :limit       => 1,
          :timeout     => -1
        }
      end
      client.search(params) do |data|
        ap data
      end
    end
  end

  desc "Inspect object"
  task :inspect, [:search_type, :query] => :environment do |t, args|
    @@config = {
      'url'                 => nil,
      'username'            => nil,
      'password'            => nil,
      'temp_path'           => nil,
      'log_file'            => nil,
      'media_base_url'      => nil
    }
    config = YAML::load(File.open("#{Rails.root}/config/rets_importer.yml"))    
    config = config[Rails.env]
    config.each { |key,val| @@config[key] = val }
    client = RETS::Client.login(
      :url      => config['url'],
      :username => config['username'],
      :password => config['password']
    )
    if args.search_type == 'Property'
      params = {
        :search_type => 'Property',
        :class       => 'Property',
        :query       => "(ListingId=#{args.query})",
        :limit       => 1,
        :timeout     => -1
      }
    elsif args.search_type == 'Agent'    
      params = {
        :search_type => 'Member',
        :class       => 'Member',
        :query       => "(MemberMlsId=#{args.query})",
        :limit       => 1,
        :timeout     => -1
      }
    elsif args.search_type == 'Office'             
      params = {
        :search_type => 'Office',
        :class       => 'Office',
        :query       => "(OfficeMlsId=#{args.query})",
        :limit       => 1,
        :timeout     => -1
      }
    elsif args.search_type == 'OpenHouse'    
      params = {
        :search_type => 'OpenHouse',
        :class       => 'OpenHouse',
        :query       => "(OpenHouseKey=#{args.query})",
        :limit       => 1,
        :timeout     => -1
      }
    end
    client.search(params) do |data|
      ap data
    end
  end

  desc "Import Image"
  task :img => :environment do 
    CabooseRets::RetsImporter.download_missing_images
  end

  desc "Re-import property details"
  task :reimport_properties => :environment do
    props = CabooseRets::Property.all
    props.each do |p|
      CabooseRets::RetsImporter.delay(:queue => 'rets', :priority => 4).import_properties(p.mls_number, false)
    end
  end

  desc "fix images"
  task :fix_images => :environment do 
    props = CabooseRets::Property.where("photo_count is not null and photo_count != ?", "0").order('id desc').all
    props.each do |p|
      puts "Checking property #{p.mls_number}"
      if p.images.count == 0
        puts "Didn't find any images, re-importing"
        CabooseRets::RetsImporter.delay(:queue => 'rets', :priority => 4).download_property_images(p)
      end
    end
  end

  desc "Reimports Property Images"
  task :reimport_property_images => :environment do
    props = CabooseRets::Property.all
    props.each do |p|
      CabooseRets::RetsImporter.log3("Property",p.mls_number,"Reimporting images for #{p.mls_number}...")
      CabooseRets::Media.where(:media_mui => p.mls_number, :media_type => 'Photo').destroy_all
      CabooseRets::RetsImporter.download_property_images(p)
    end
  end

  desc "Import rets data"
  task :import => :environment do
    CabooseRets::RetsImporter.import('Member'    , "(MemberStatus=Active)")
    CabooseRets::RetsImporter.import('Property'  , "(MlsStatus=Active)")
    CabooseRets::RetsImporter.import('Office'    , "(OfficeStatus=Active)")    
    CabooseRets::RetsImporter.import('OpenHouse' , "(OpenHouseKeyNumeric=0+)")
  end
  
  desc "Single Import Test"
  task :import_one => :environment do
    CabooseRets::RetsImporter.import_properties('131330',true)
  end

  desc "Purge rets data"
  task :purge => :environment do
    CabooseRets::RetsImporter.purge_helper('Property', '2013-08-06')
    CabooseRets::RetsImporter.purge_helper('Office', '2012-01-01')
    CabooseRets::RetsImporter.purge_helper('Member', '2012-01-01')
    CabooseRets::RetsImporter.purge_helper('OpenHouse', '2012-01-01')
  end

  desc "update helper"
  task :uh => :environment do
    CabooseRets::RetsImporter.update_helper('Property', last_updated, false)
  end

  #desc "Delete old rets properties"
  #task :delete_old_properties => :environment do
  #  CabooseRets::RetsImporter.delete_old_properties
  #end

  desc "Update search options"
  task :update_search_options => :environment do
    CabooseRets::SearchOption.update_search_options
  end

  desc "Initializes the database for a caboose installation"
  task :rename_media => :environment do
    CabooseRets::Media.rename_media
  end

  desc "Initializes the database for a caboose installation"
  task :db => :environment do
    CabooseRets::Schema.create_schema
    CabooseRets::Schema.load_data
  end

  desc "Verifies all tables and columns are created."
  task :create_schema => :environment do CabooseRets::Schema.create_schema end

  desc "Loads data into caboose tables"
  task :load_data => :environment do CabooseRets::Schema.load_data end

  desc "Updates all the listings from MLS"
  task :update_rets => :environment do
    if task_is_locked
      CabooseRets::RetsImporter.log("caboose_rets:update_rets task is locked. Aborting.")
      next
    end
    CabooseRets::RetsImporter.log("Updating rets data...")
    task_started = lock_task

    begin
      # RetsImporter.update_all_after(last_updated - Rational(1,86400))
      CabooseRets::RetsImporter.update_after(last_updated, true)
		  save_last_updated(task_started)
		  unlock_task
		rescue
		  raise
		ensure
		  unlock_task_if_last_updated(task_started)
    end
  end

  def last_updated
    if !Caboose::Setting.exists?(:name => 'rets_last_updated')
      Caboose::Setting.create(:name => 'rets_last_updated', :value => '2013-08-06T00:00:01')
    end
    s = Caboose::Setting.where(:name => 'rets_last_updated').first
    return DateTime.parse(s.value)
  end

  def save_last_updated(d)
    s = Caboose::Setting.where(:name => 'rets_last_updated').first
    s.value = d.strftime('%FT%T')
    s.save
  end

  def task_is_locked
    return Caboose::Setting.exists?(:name => 'rets_update_running')
  end

  def lock_task
    date = DateTime.now
    Caboose::Setting.create(:name => 'rets_update_running', :value => date.strftime('%F %T'))
    return date
  end

  def unlock_task
    Caboose::Setting.where(:name => 'rets_update_running').first.destroy
  end

  def unlock_task_if_last_updated(d)
    setting = Caboose::Setting.where(:name => 'rets_update_running').first
    unlock_task if setting && d.strftime('%F %T') == setting.value
  end

end
