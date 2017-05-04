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
    client = RETS::Client.login(
      :url      => 'http://rets.wamls.mlsmatrix.com/rets/Login.ashx',
      :username => 'RETS_6',
      :password => 'ellis'
    )
    type.each do |t|
      if t == 'p'
        params = {
          :search_type => 'Property',
          :class       => 'Listing',
          :query       => "(Matrix_Unique_ID=0+)",
          :limit       => 1,
          :timeout     => -1
        }
      elsif t == 'a'      
        params = {
          :search_type => 'Agent',
          :class       => 'Agent',
          :query       => "(Matrix_Unique_ID=0+)",
          :limit       => 1,
          :timeout     => -1
        }
      elsif t == 'o'                
        params = {
          :search_type => 'Office',
          :class       => 'Office',
          :query       => "(Matrix_Unique_ID=0+)",
          :limit       => 1,
          :timeout     => -1
        }
      elsif t == 'oh'       
        params = {
          :search_type => 'OpenHouse',
          :class       => 'OpenHouse',
          :query       => "(Matrix_Unique_ID=0+)",
          :limit       => 1,
          :timeout     => -1
        }
      end

      client.search(params) do |data|
        ap data
      end
    end
  end

  desc "Import Image"
  task :img => :environment do 
    p = CabooseRets::Property.where(:matrix_unique_id => "1026532").first
    CabooseRets::RetsImporter.download_property_images(p)
  end

  desc "Import rets data"
  task :import => :environment do
    CabooseRets::RetsImporter.import('Agent'    , "(Matrix_Unique_ID=0+)")
    CabooseRets::RetsImporter.import('Listing'  , "(Matrix_Unique_ID=0+)")
    CabooseRets::RetsImporter.import('Office'   , "(Matrix_Unique_ID=0+)")    
    CabooseRets::RetsImporter.import('OpenHouse', "(Matrix_Unique_ID=0+)")
  end
  
  desc "Single Import Test"
  task :import_one => :environment do
    CabooseRets::RetsImporter.import_properties('1026532'  , "(Matrix_Unique_ID=1026532)")
  end

  desc "Purge rets data"
  task :purge => :environment do
    CabooseRets::RetsImporter.purge_helper('Listing', '2013-08-06')
    CabooseRets::RetsImporter.purge_helper('Office', '2012-01-01')
    CabooseRets::RetsImporter.purge_helper('Agent', '2012-01-01')
    CabooseRets::RetsImporter.purge_helper('OpenHouse', '2012-01-01')
  end

  desc "update helper"
  task :uh => :environment do
    CabooseRets::RetsImporter.update_helper('Listing', last_updated)
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
      CabooseRets::RetsImporter.update_after(last_updated)
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
