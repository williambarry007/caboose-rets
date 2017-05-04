
class CabooseRets::AgentMeta < ActiveRecord::Base
  self.table_name = "rets_agents_meta"
  belongs_to :agent, :foreign_key => 'matrix_unique_id', :primary_key => 'la_code'
  has_attached_file :image,
    :path => 'rets/agents/:la_code_:style.:extension',
    :styles => {
      :thumb => '100x150>',
      :large => '200x300>'
    }
  do_not_validate_attachment_file_type :image
  attr_accessible :id,
    :la_code         ,
    :hide            ,
    :bio             ,
    :contact_info    ,
    :assistant_to    ,
    :designation     ,
    :image_location

end
