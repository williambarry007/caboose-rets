
module CabooseRets
  class LandController < ApplicationController  
     
    # GET /land
    def index
      @gen = Caboose::PageBarGenerator.new(params, {          
          'acreage'                     => '',
          'acreage_gte'                 => '',
          'acreage_lte'                 => '',
          'acreage_source'              => '',
          'adjoining_land_use'          => '',
          'agent_notes_like'            => '',
          'area'                        => '',
          'bom_date'                    => '',                    
          'city'                        => '',
          'city_code'                   => '',
          'co_la_code'                  => '',
          'co_lo_code'                  => '',
          'co_sa_code'                  => '',
          'co_so_code'                  => '',          
          'converted'                   => '',
          'county'                      => '',
          'current_price_gte'           => '',
          'current_price_lte'           => '',
          'date_created_gte'            => '',
          'date_created_lte'            => '',
          'date_modified_gte'           => '',
          'date_modified_lte'           => '',          
          'elem_school'                 => '',          
          'ftr_access_like'             => '',          
          'ftr_lotdesc_like'            => '',
          'ftr_mineralrights'           => '',                    
          'ftr_zoning'                  => '',          
          'high_school'                 => '',
          'internet_yn'                 => '',
          'la_code'                     => '',          
          'list_date_gte'               => '',
          'list_date_lte'               => '',
          'list_price_gte'              => '',
          'list_price_lte'              => '',          
          'lo_code'                     => '',
          'middle_school'               => '',
          'mls_acct'                    => '',
          'municipality'                => '',
          'parcel_id'                   => '',
          'prop_type'                   => '',
          'remarks_like'                => '',          
          'sa_code'                     => '',                    
          'so_code'                     => '',          
          'state'                       => '',
          'status'                      => 'Active',
          'address_like'                => '',          
          'street_name_like'            => '',
          'street_num_like'             => '',          
          'subdivision'                 => '',          
          'unit_num'                    => '',          
          'waterfront'                  => '',
          'waterfront_yn'               => '',
          'zip'                         => ''    
        },{
          'model'           => 'CabooseRets::LandProperty',
          'sort'            => CabooseRets::default_property_sort,          
          'desc'            => false,
          'skip'            => ['status'],
          'abbreviations'   => {
            'address_like' => 'street_num_concat_street_name_like' 
          },          
          'base_url'        => '/land/search',          
          'items_per_page'  => 10
      })
      
      @properties = @gen.items
      if params[:waterfront].present? then @properties.reject!{|p| p.waterfront.blank?} end

      @block_options = {
        :properties   => @properties,
        :saved_search => nil,
        :pager => @gen 
      }

    end
    
    # GET /land/:mls_acct/details
    def details
      @property = CabooseRets::LandProperty.where(:mls_acct => params[:mls_acct]).first
      @saved = logged_in? && SavedProperty.where(:user_id => logged_in_user.id, :mls_acct => params[:mls_acct]).exists?
      if @property.nil?
        @mls_acct = params[:mls_acct]
        CabooseRets::RetsImporter.delay.import_property(@mls_acct.to_i)
        render 'land/not_exists'
        return
      end
      @block_options = {
        :mls_acct => params[:mls_acct],
        :property => @property,
        :saved    => @saved,
        :agent    => @property ? Agent.where(:la_code => @property.la_code).first : nil,
        :form_authenticity_token => form_authenticity_token        
      }
    end
    
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # GET /admin/land
    def admin_index
      return if !user_is_allowed('properties', 'view')
        
      @gen = Caboose::PageBarGenerator.new(params, {          
          'mls_acct'    => ''
      },{
          'model'       => 'CabooseRets::LandProperty',
          'sort'        => 'mls_acct',
          'desc'        => false,
          'base_url'    => '/admin/land',
          'use_url_params'  => false
      })
      @properties = @gen.items    
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/land/:mls_acct/edit
    def admin_edit
      return if !user_is_allowed('properties', 'edit')    
      @property = LandProperty.where(:mls_acct => params[:mls_acct]).first
      render :layout => 'caboose/admin'
    end        

    # GET /admin/land/:mls_acct/refresh
    def admin_refresh
      return if !user_is_allowed('properties', 'edit')
      
      p = LandProperty.find(params[:mls_acct])            
      p.delay.refresh_from_mls
           
      resp = Caboose::StdClass.new
      resp.success = "The property's info is being updated from MLS. This may take a few minutes depending on how many images it has."
      render :json => resp            
    end
   
  end
end