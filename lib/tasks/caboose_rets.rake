require "caboose_rets/version"

namespace :caboose_rets do
  
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
