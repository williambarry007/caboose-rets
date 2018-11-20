module CabooseRets  
  class SavedSearchesController < ApplicationController
     
    # GET /saved-searches
    def index
      return if !verify_logged_in
      @searches = SavedSearch.where(:user_id => logged_in_user.id).all
      render :layout => 'caboose/modal'
    end
  
    # POST /saved-searches
    def add
      return if !verify_logged_in      
      
      resp = Caboose::StdClass.new
      
      if SavedSearch.exists?(:uri => params[:uri])
        resp.redirect = "/saved-searches"
      else        
        search = SavedSearch.new(
          :user_id        => logged_in_user.id,
          :date_last      => Date.today,
          :interval       => 1,
          :notify         => true,
          :uri            => params[:uri],
          :property_type  => params[:property_type],
          :params         => params[:params]        
        )
        if search.save
          resp.redirect = "/saved-searches"        
        else
          resp.error = "There was an error saving your search."        
        end
      end
      render :json => resp
    end
  
    # GET /saved-searches/:id
    def redirect
      return if !verify_logged_in
      @search = SavedSearch.find(params[:id])
      redirect_to @search.uri      
    end        
      
    # PUT /saved-searches/:id
    def update      
      return if !verify_logged_in
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      search = SavedSearch.find(params[:id])    
      
      save = true
      params.each do |name,value|
        case name
          when 'interval'
            search.interval = value
            resp.attributes['interval'] = { 'text' => "#{value}" }          
  		  end
  		end
  		resp.success = save && search.save  
      render :json => resp
    end
    
    # DELETE /saved-searches/:id
    def delete
      return if !verify_logged_in
      
      resp = Caboose::StdClass.new               
      search = SavedSearch.find(params[:id])
      
      if search
        search.destroy
        resp.success = "The saved search has been deleted."                
      else
        resp.error = "There was an error deleting your search."        
      end
      
      render :json => resp
    end

  end
end
