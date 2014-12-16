
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
        'acreage_gte'        => '',
        'acreage_lte'        => '',
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
        'lo_lo_code'         => '',
        'remarks_like'       => '',
        'waterfront'         => '',
        'ftr_lotdesc_like'   => '',
        'mls_acct'           => '',
        'subdivision'        => '',
        'foreclosure_yn'     => '',
        'address_like'       => '',        
        'street_name_like'   => '',
        'street_num_like'    => '',
        'date_created_gte'   => '',
        'date_created_lte'   => '',
        'date_modified_gte'  => '',
        'date_modified_lte'  => '',
        'status'             => 'Active'
      },{
        'model'           => 'CabooseRets::ResidentialProperty',
        'sort'            => CabooseRets::default_property_sort,
        'desc'            => false,
        'abbreviations'   => { 
          'address_like' => 'street_num_concat_street_name_like'  
        },
        'skip'            => ['status'],
        'base_url'        => '/residential/search',
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
      @saved = logged_in? && SavedProperty.where(:user_id => logged_in_user.id, :mls_acct => params[:mls_acct]).exists? 
      if @property && @property.lo_code == '46'
        @agent = Agent.where(:la_code => @property.la_code).first
      end
      if @property.nil?
        @mls_acct = params[:mls_acct]        
        CabooseRets::RetsImporter.delay.import_property(@mls_acct.to_i)      
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
          'base_url' => '/admin/residential',
          'use_url_params'  => false
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
      return if !user_is_allowed('properties', 'edit')

      p = ResidentialProperty.find(params[:mls_acct])
      p.delay.refresh_from_mls
      
      resp = Caboose::StdClass.new
      resp.success = "The property's info is being updated from MLS. This may take a few minutes depending on how many images it has."
      render :json => resp
    end
   
  end
end
