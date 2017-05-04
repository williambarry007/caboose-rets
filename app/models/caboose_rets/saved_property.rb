
class CabooseRets::SavedProperty < ActiveRecord::Base
  self.table_name = "rets_saved_properties"
  belongs_to :user, :class_name => 'Caboose::User'
  attr_accessible :user_id, :mls

  def property
    return CabooseRets.get_property(self.mls)            
  end
end
