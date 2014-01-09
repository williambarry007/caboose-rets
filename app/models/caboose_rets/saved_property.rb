
class CabooseRets::SavedProperty < ActiveRecord::Base
  self.table_name = "rets_saved_properties"
  belongs_to :user, :class_name => 'Caboose::User'  
  attr_accessible :user_id, :mls_acct
  
  def property
    return CabooseRets.get_property(self.mls_acct)            
  end
end
