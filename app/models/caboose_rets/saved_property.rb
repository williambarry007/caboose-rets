class CabooseRets::SavedProperty < ActiveRecord::Base
  self.table_name = "rets_saved_properties"
  
  belongs_to :user, :class_name => 'Caboose::User'
  attr_accessible :user_id, :mls_number, :date_saved

  def property
    return CabooseRets::Property.where(:mls_number => self.mls_number).first     
  end

end
