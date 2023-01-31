
class CabooseRets::Media < ActiveRecord::Base
  self.table_name = "rets_media"
  
  has_attached_file :file, :path => 'rets/media/:mls_:id.:extension'
  do_not_validate_attachment_file_type :file
  has_attached_file :image,
    :path => 'rets/media/:mls_:media_order_:style.:extension',
    :styles => {
      :tiny  => '160x120>',
      :thumb => '400x300>',
      :large => '640x480>',
      :huge => '1200x1200>'
    }
  do_not_validate_attachment_file_type :image
  # attr_accessible :date_modified, :file_name, :media_id, :media_order, :media_remarks, :media_type, :mls, :url

  def parse(data,content)
    # self.date_modified  = data['DATE_MODIFIED']
    # self.file_name 		  = data['FILE_NAME']
    # self.media_id 		  = data['MEDIA_ID']
    # self.media_order 	  = data['MEDIA_ORDER'].to_i
    # self.media_remarks  = data['MEDIA_REMARKS']    
    # self.mls 		        = data['MLS']
    self.media_type      = data['MediaCategory']
    self.media_mui       = data['content-id']
    self.media           = Caboose::Media.create(
                  :image => content,
    #               :image => content,
                  :image_content_type => data['content-type']
          )
    # self.media.save      
	end

	before_post_process :lowercase_file_names

  def lowercase_file_names
    self.image.instance_write(:file_name, self.image_file_name.downcase) if self.image_file_name
    self.file.instance_write(:file_name, self.file_file_name.downcase)   if self.file_file_name
  end

  #before_post_process :rename_avatar
  #def rename_image
  #  extension = File.extname(image_file_name).downcase
  #  self.image.instance_write :file_name, "#{self.mls}_#{self.media_order}.#{extension}"
  #end

  def self.reorder(media_ids, bucket_name)

    # s3 = AWS::S3.new
    # b = s3.buckets[bucket_name]

    # # Rename the s3 assets to temp names
    # media_ids.each do |id|
    #   m = CabooseRets::Media.find(id)
    #   (m.image.styles.keys+[:original]).each { |style| b.objects[m.image.path(style)].rename_to "#{m.image.path(style)}.temp" } if m.media_type == 'Photo'
    #   b.objects[m.file.path].rename_to "#{m.file.path}.temp" if m.media_type == 'File'
    # end

    # # Rename the assets to their new names
    # i = 1
    # j = 1
    # media_ids.each do |id|
    #   m = CabooseRets::Media.find(id)
    #   if m.media_type == 'Photo'
    #     orig_name = "#{m.image.path}.temp"
    #     m.media_order = i
    #     (m.image.styles.keys+[:original]).each { |style| b.objects[orig_name.gsub("original", style.to_s)].rename_to m.image.path(style) }
    #     m.save
    #     i = i + 1
    #   elsif m.media_type == 'File'
    #     b.objects["#{m.file.path}.temp"].rename_to m.file.path
    #     m.media_order = j
    #     m.save
    #     j = j + 1
    #   end
    # end

    # return true
  end

  def self.reorder(media_ids, bucket_name)

    # s3 = AWS::S3.new
    # b = s3.buckets[bucket_name]

    # # Rename the s3 assets to temp names
    # media_ids.each do |id|
    #   m = CabooseRets::Media.find(id)
    #   (m.image.styles.keys+[:original]).each { |style| b.objects[m.image.path(style)].rename_to "#{m.image.path(style)}.temp" } if m.media_type == 'Photo'
    #   b.objects[m.file.path].rename_to "#{m.file.path}.temp" if m.media_type == 'File'
    # end

    # # Rename the assets to their new names
    # i = 1
    # j = 1
    # media_ids.each do |id|
    #   m = CabooseRets::Media.find(id)
    #   if m.media_type == 'Photo'
    #     orig_name = "#{m.image.path}.temp"
    #     m.media_order = i
    #     (m.image.styles.keys+[:original]).each { |style| b.objects[orig_name.gsub("original", style.to_s)].rename_to m.image.path(style) }
    #     m.save
    #     i = i + 1
    #   elsif m.media_type == 'File'
    #     b.objects["#{m.file.path}.temp"].rename_to m.file.path
    #     m.media_order = j
    #     m.save
    #     j = j + 1
    #   end
    # end

    # return true
  end

  def self.rename_media
    # s3 = AWS::S3.new
    # b = s3.buckets["advantagerealtygroup"]

    # CabooseRets::Media.where(:media_type => 'Photo').reorder("mls, media_order").all.each do |m|
    #   puts "Renaming #{m.mls}_#{m.id}..."
    #   if m.image_file_name && m.image
    #     ext = File.extname(m.image_file_name)
    #     (m.image.styles.keys+[:original]).each do |style|
    #       b.objects[m.image.path(style)].copy_to "rets/media_new/#{m.id}_#{style}.#{ext}" if b.objects[m.image.path(style)].exists?
    #     end
    #   end
    # end

    # return true
  end

  def image_url(style)
    if CabooseRets::use_hosted_images == true
      return "#{CabooseRets::media_base_url}/#{self.file_name}"
    end
    return "" if self.image.nil?
    return self.image.url(style)
  end

end
