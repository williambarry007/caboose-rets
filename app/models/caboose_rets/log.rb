class CabooseRets::Log < ActiveRecord::Base
  self.table_name = "rets_logs"
  
  attr_accessible :id, :timestamp, :class_name, :object_id, :text

end