
module CabooseRets
  class MediaController < ApplicationController  
    
    # GET /admin/media/:id
    def admin_index
      return if !user_is_allowed('media', 'view')
      m = Media.find(params[:id])
      render :json => media_hash(m)
    end
  
    # GET /admin/properties/:mls_acct/media    
    def admin_property_media
      return if !user_is_allowed('media', 'view')      
      @property = CabooseRets.get_property(params[:mls_acct])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/properties/:mls_acct/photos
    def admin_photos
      return if !user_is_allowed('media', 'view')      
      media = Media.where(:mls_acct => params[:mls_acct], :media_type => 'Photo').reorder(:media_order).all
      media2 = media.collect { |m| media_hash(m) }      	      
      render :json => media2
    end
    
    # GET /admin/properties/:mls_acct/files
    def admin_files
      return if !user_is_allowed('media', 'view')      
      media = Media.where(:mls_acct => params[:mls_acct], :media_type => 'File').reorder(:media_order).all
      media2 = media.collect { |m| media_hash(m) }      	      
      render :json => media2
    end

    # POST /admin/properties/:mls_acct/photos
    def admin_add_photo
      return if !user_is_allowed('media', 'edit')      
            
      x = Media.maximum(:media_order, :conditions => {:mls_acct => params[:mls_acct], :media_type => 'Photo'})
      x = 0 if x.nil?
      
      m = Media.new
      m.id            = Media.maximum(:id) + 1
      m.mls_acct 		  = params[:mls_acct]
      m.date_modified = DateTime.now                  
      m.media_order   = x + 1
      m.media_type 		= 'Photo'
      m.image         = params[:image]
      m.save
      
      render :text => "<script type='text/javascript'>parent.controller.after_image_upload();</script>"                        
    end

    # POST /admin/properties/:msl_acct/files
    def admin_add_file
      return if !user_is_allowed('media', 'edit')

      x = Media.maximum(:media_order, :conditions => {:mls_acct => params[:mls_acct], :media_type => 'File'})
      x = 0 if x.nil?      
                  
      m = Media.new
      m.id            = Media.maximum(:id) + 1
      m.mls_acct 		  = params[:mls_acct]
      m.date_modified = DateTime.now                  
      m.media_order   = x + 1
      m.media_type 		= 'File'
      m.file          = params[:file]
      m.save
      
      render :text => "<script type='text/javascript'>parent.controller.after_file_upload();</script>"        
    end

    # DELETE /admin/media/:id
    def admin_delete
      return if !user_is_allowed('media', 'delete')
      Media.find(params[:id]).destroy            
      render :json => true
    end
    
    # PUT /admin/properties/:mls_acct/media/order
    def admin_update_order
      return if !user_is_allowed('media', 'delete')      
      Media.reorder(params[:sort], "advantagerealtygroup")            
      render :json => true
    end
    
    private
    
    def media_hash(m)
      {      
        :id             => m.id,
        :date_modified  => m.date_modified,  
        :file_name 		  => m.file_name,
        :media_id 		  => m.media_id,
        :media_order 	  => m.media_order,
        :media_remarks  => m.media_remarks,
        :media_type 		=> m.media_type,
        :mls_acct 		  => m.mls_acct,
        :url 		        => m.url,          
        :image => {
          :file_name    => m.image_file_name,
          :content_type => m.image_content_type,
          :file_size    => m.image_file_size,
          :update_at    => m.image_updated_at,
          :tiny_url     => m.image.url(:tiny),
          :thumb_url    => m.image.url(:thumb),
          :large_url    => m.image.url(:large)            
        },
        :file => {
          :file_name    => m.file_file_name,
          :content_type => m.file_content_type,
          :file_size    => m.file_file_size,
          :update_at    => m.file_updated_at,
          :url          => m.file.url
        }            
      }
    end
          
  end
end
