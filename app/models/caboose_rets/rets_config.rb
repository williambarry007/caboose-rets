class CabooseRets::RetsConfig < ActiveRecord::Base
  self.table_name = "rets_configs"
  
  belongs_to :site, :class_name => 'Caboose::Site'

  attr_accessible :id,
    :site_id,
    :office_mls,
    :office_mui,
    :agent_mls,
    :agent_mui,
    :rets_url,
    :rets_username,
    :rets_password,
    :default_sort

end
