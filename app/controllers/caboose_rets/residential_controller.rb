
module CabooseRets
  class ResidentialController < ApplicationController  
     
    # GET /residential
    def index
    	params[:street_num_like] = params[:street_name_like].tr('A-z', '').tr(' ', '') unless params[:street_name_like].nil?
    	unless params[:street_name_like].nil?
    		params[:street_name_like] = params[:street_name_like].tr('0-9', "") 
    		until params[:street_name_like][0] != " " || params[:street_name_like] == ''
    			params[:street_name_like][0] = '' if params[:street_name_like][0].to_i == 0
    		end
    	end
    	
      @gen = Caboose::PageBarGenerator.new(params, {
        'name'               => '',
        'current_price_gte'  => '',
        'current_price_lte'  => '',
        'bedrooms_gte'       => '',
        'bedrooms_lte'       => '',
        'prop_type'          => '',
        'tot_heat_sqft_gte'  => '',
        'tot_heat_sqft_lte'  => '',
        'neighborhood'       => '',
        'elem_school'        => '',
        'middle_school'      => '',
        'high_school'        => '',
        'address'            => '',
        'lo_lo_code'         => '',
        'remarks_like'       => '',
        'waterfront'         => '',
        'ftr_lotdesc_like'   => '',
        'mls_acct'           => '',
        'subdivision'        => '',
        'foreclosure_yn'     => '',
        'street_name_like'   => '',
        'street_num_like'    => '',
        'date_created_gte'   => '',
        'date_created_lte'   => '',
        'date_modified_gte'  => '',
        'date_modified_lte'  => '',
        'status'             => ['active', 'pending']
      },{
        'model'           => 'CabooseRets::ResidentialProperty',
        'sort'            => 'current_price ASC, mls_acct',
        'desc'            => false,
        'base_url'        => '/residential',
        'items_per_page'  => 10
      })
      
      @properties = @gen.items      
    
      if params[:waterfront].present? then @properties.reject!{|p| p.waterfront.blank?} end
      if params[:ftr_lotdesc] == 'golf' then @properties.reject!{|p| p.ftr_lotdesc != 'golf'} end
      #if params[:foreclosure] then @properties.reject!{|p| p.foreclosure_yn != "Y"} end
      
      @saved_search = nil
      if CabooseRets::SavedSearch.exists?(:uri => request.fullpath)
        @saved_search = CabooseRets::SavedSearch.where(:uri => request.fullpath).first
      end
    end
    
    # GET /residential/:mls_acct/details
    def details
      @property = ResidentialProperty.where(:mls_acct => params[:mls_acct]).first
      if @property.lo_code == '46'
        @agent = Agent.where(:la_code => @property.la_code).first
      end
      if @property.nil?
        @mls_acct = params[:mls_acct]
        render 'residential/residential_not_exists'
        return
      end
      #@message = Message.new    
    end
    
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # GET /admin/residential
    def admin_index
      return if !user_is_allowed('properties', 'view')
        
      @gen = Caboose::PageBarGenerator.new(params, {
          'mls_acct'     => ''
      },{
          'model'    => 'CabooseRets::ResidentialProperty',
          'sort'     => 'mls_acct',
          'desc'     => false,
          'base_url' => '/admin/residential'
      })
      @properties = @gen.items    
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/residential/:mls_acct/edit
    def admin_edit
      return if !user_is_allowed('properties', 'edit')    
      @property = ResidentialProperty.where(:mls_acct => params[:mls_acct]).first
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/residential/:mls_acct/refresh
    def admin_refresh        
      p = ResidentialProperty.find(params[:mls_acct])        
      RetsImporter.import("(MLS_ACCT=#{p.mls_acct})", 'Property', 'RES')
      RetsImporter.download_property_images(p)
      render :json => Caboose::StdClass.new({ 'success' => "The property's info has been updated from MLS." })
    end
   
  end
end
