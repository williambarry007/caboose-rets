
module CabooseRets
  class MultiFamilyController < ApplicationController  
     
    # GET /multi-family
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
        'status'             => 'Active'                
      },{
        'model'           => 'CabooseRets::MultiFamilyProperty',
        'sort'            => 'current_price ASC, mls_acct',
        'desc'            => false,
        'base_url'        => '/multi-family',
        'items_per_page'  => 10
      })      
      @properties = @gen.items
    end
    
    # GET /multi_family/:mls_acct/details
    def details
      @property = MultiFamilyProperty.where(:mls_acct => params[:mls_acct]).first
      @saved = logged_in? && SavedProperty.where(:user_id => logged_in_user.id, :mls_acct => params[:mls_acct]).exists?      
      if @property.nil?
        @mls_acct = params[:mls_acct]
        render 'multi_family/not_exists'
        return
      end          
    end
    
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # GET /admin/multi_family
    def admin_index
      return if !user_is_allowed('properties', 'view')
        
      @gen = Caboose::PageBarGenerator.new(params, {
          'mls_acct'     => ''
      },{
          'model'    => 'CabooseRets::MultiFamilyProperty',
          'sort'     => 'mls_acct',
          'desc'     => false,
          'base_url' => '/admin/multi_family'
      })
      @properties = @gen.items    
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/multi_family/:mls_acct/edit
    def admin_edit
      return if !user_is_allowed('properties', 'edit')    
      @property = MultiFamilyProperty.where(:mls_acct => params[:mls_acct]).first
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/multi_family/:mls_acct/refresh
    def admin_refresh
      p = MultiFamilyProperty.find(params[:mls_acct])        
      RetsImporter.import("(MLS_ACCT=#{p.mls_acct})", 'Property', 'LND')
      RetsImporter.download_property_images(p)
      render :json => Caboose::StdClass.new({ 'success' => "The property's info has been updated from MLS." })
    end
   
  end
end
