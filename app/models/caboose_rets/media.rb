
class CabooseRets::Media < ActiveRecord::Base
  self.table_name = "rets_media"
  
  has_attached_file :file, :path => 'rets/media/:mls_acct_:media_order.:extension' 
  has_attached_file :image, 
    :path => 'rets/media/:mls_acct_:media_order_:style.:extension', 
    :styles => {
      :tiny  => '160x120>',
      :thumb => '400x300>',
      :large => '640x480>'
    }
  attr_accessible :date_modified, :file_name, :media_id, :media_order, :media_remarks, :media_type, :mls_acct, :url
  
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
	
	before_post_process :lowercase_file_names
  
  def lowercase_file_names    
    self.image.instance_write(:file_name, self.image_file_name.downcase) if self.image_file_name 
    self.file.instance_write(:file_name, self.file_file_name.downcase)   if self.file_file_name    
  end

  #before_post_process :rename_avatar    
  #def rename_image    
  #  extension = File.extname(image_file_name).downcase    
  #  self.image.instance_write :file_name, "#{self.mls_acct}_#{self.media_order}.#{extension}"
  #end
  
  def self.reorder(media_ids, bucket_name)
    
    s3 = AWS::S3.new
    b = s3.buckets[bucket_name]
    
    # Rename the s3 assets to temp names
    media_ids.each do |id|
      m = CabooseRets::Media.find(id)
      (m.image.styles.keys+[:original]).each { |style| b.objects[m.image.path(style)].rename_to "#{m.image.path(style)}.temp" } if m.image
      (m.file.styles.keys+[:original]).each  { |style| b.objects[m.file.path(style) ].rename_to "#{m.file.path(style)}.temp"  } if m.file
    end
    
    # Rename the assets to their new names
    i = 1
    media_ids.each do |id|
      m = CabooseRets::Media.find(id)                      
      orig_image_name = m.image ? "#{m.image.path}.temp" : nil
      orig_file_name  = m.file  ? "#{m.image.path}.temp" : nil
      m.media_order = i      
      (m.image.styles.keys+[:original]).each { |style| b.objects[orig_image_name.gsub("original", style.to_s)].rename_to m.image.path(style) } if m.image
      (m.file.styles.keys+[:original]).each  { |style| b.objects[orig_file_name.gsub( "original", style.to_s)].rename_to m.file.path(style)  } if m.file
      m.save
      i = i + 1
    end
    
    return true
  end
    
end
