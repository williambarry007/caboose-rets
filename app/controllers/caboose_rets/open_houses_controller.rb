require "open-uri"

module CabooseRets
  class OpenHousesController < ApplicationController  
     
    # GET /admin/open-houses/new
    def admin_new
      return if !user_is_allowed('post', 'new')  
      @post = Caboose::Post.new  
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/open-houses
    def admin_add
      return if !user_is_allowed('post', 'add')
  
      resp = Caboose::StdClass.new({
        'error' => nil,
        'redirect' => nil
      })
  
      mls = params[:mls]        
      post = post_from_mls(mls)
  
      if post.nil?
        resp.error = "No property with MLS id #{params[:mls]}."
      else
        post.published = false      
        post.save
        resp.redirect = "/admin/posts/#{post.id}/edit"
      end
      
      render :json => resp
    end
    
    def post_from_mls(mls)
      post = nil
      [ResidentialProperty, CommercialProperty, CommercialProperty].each_with_index do |type, i|
        
        prop = type.find(mls)
        next if prop.nil?      
        ptype = ['residential', 'commercial', 'land'][i]
        
        d = params[:date_time]
        post = Caboose::Post.new
        post.title = "Open House on #{d} at #{prop.street_num.to_s} #{prop.street_name.titleize}"
              
        post.body = ""
        post.body << "<p>#{prop.remarks}</p>" if prop.remarks and !prop.remarks.strip.empty?
        post.body << "\n<p>Directions: #{prop.directions}</p>" if prop.directions and !prop.directions.strip.empty?
        post.body << "\n<p><a href='/#{ptype}/#{prop.id}/details'>More details</a></p>"
         
        post.image = open("https://s3.amazonaws.com/advantagerealtygroup.com/#{ptype}/#{mls}_1_original.jpg")
        
        break
      end
      return post    
    end
  end
end
