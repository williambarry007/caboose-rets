
class CabooseRets::Media < ActiveRecord::Base
  self.table_name = "rets_media"
  
  has_attached_file :image, 
    :path => 'rets/media/:mls_acct_:media_order_:style.:extension', 
    :styles => {
      :tiny  => '160x120>',
      :thumb => '400x300>',
      :large => '640x480>'
    }
  
  def parse(data)
    self.date_modified  = data['DATE_MODIFIED']
    self.file_name 		  = data['FILE_NAME']
    self.media_id 		  = data['MEDIA_ID']
    self.media_order 	  = data['MEDIA_ORDER']
    self.media_remarks  = data['MEDIA_REMARKS']
    self.media_type 		= data['MEDIA_TYPE']
    self.mls_acct 		  = data['MLS_ACCT']
    self.url 		        = data['URL']
	end
end
