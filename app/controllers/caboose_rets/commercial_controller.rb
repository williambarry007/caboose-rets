
module CabooseRets
  class CommercialController < ApplicationController  
     
    # GET /commercial
    def index
      @gen = Caboose::PageBarGenerator.new(params, {
          'name'                      => '',
          'current_price_gte'         => '',
          'current_price_lte'         => '',
          'prop_type'                 => '',
          'tot_heat_sqft_gte'         => '',
          'city'                      => '',
          'county'                    => '',
          'zip'                       => '',
          'mls_acct'                  => '',
         # 'added_by_advantage'        => '',
          'lo_code'                   => '',
          'address'                   => '',
          'status'                    => ['Active', 'Pending']
      },{
          'model'           => 'CabooseRets::CommercialProperty',
          'sort'            => 'mls_acct',
          'desc'            => false,
          'base_url'        => '/commercial',
          'items_per_page'  => 10
      })
      @properties = @gen.items
    end
    
    # GET /commercial/:mls_acct/details
    def details
      @property = CommercialProperty.where(:mls_acct => params[:mls_acct]).first      
    end
    
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # GET /admin/commercial
    def admin_index
      return if !user_is_allowed('properties', 'view')
        
      @gen = Caboose::PageBarGenerator.new(params, {
          'name'       => ''
      },{
          'model'       => 'CabooseRets::CommercialProperty',
          'sort'        => 'mls_acct',
          'desc'        => false,
          'base_url'    => '/admin/commercial'
      })
      @properties = @gen.items    
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/commercial/new
    def admin_new
      return if !user_is_allowed('properties', 'edit')
      @agents = Agent.reorder("last_name, first_name").all
      @offices = Office.reorder("lo_name")
      render :layout => 'caboose/admin'      
    end
    
    # POST /admin/commercial
    def admin_add
      return if !user_is_allowed('properties', 'edit')      
       
      max_id = 1000001
      if CommercialProperty.where("id > 1000000").count > 0
        max_id = CommercialProperty.maximum(:id, :conditions => ['id > 1000000'])
      end      
                  
      p = CommercialProperty.new      
      p.id = max_id + 1
      p.mls_acct = p.id
      p.la_code = params[:la_code]      
      p.lo_code = params[:lo_code]            
      p.save
      
      render :json => Caboose::StdClass.new({
        'redirect' => "/admin/commercial/#{p.id}/edit"  
      })        
    end    
    
    # GET /admin/commercial/:mls_acct/edit
    def admin_edit
      return if !user_is_allowed('properties', 'edit')    
      @property = CommercialProperty.where(:mls_acct => params[:mls_acct]).first
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/commercial/:mls_acct
    def admin_update
      return if !user_is_allowed('properties', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      property = CommercialProperty.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name        
          when 'acreage',
            'adjoining_land_use',
            'agent_notes',
            'agent_other_contact_desc',
            'agent_other_contact_phone',
            'annual_taxes',
            'approx_age',
            'area',
            'baths',
            'baths_full',
            'baths_half',
            'bedrooms',
            'bom_date',
            'book_number',
            'book_page',
            'book_type',
            'box_on_unit',
            'box_on_unit_yn',
            'business_included_yn',
            'buyer_broker',
            'buyer_broker_type',
            'buyer_city',
            'buyer_name',
            'buyer_state',
            'buyer_zip',
            'category',
            'city',
            'city_code',
            'co_la_code',
            'co_lo_code',
            'co_sa_code',
            'co_so_code',
            'contacts',
            'contr_broker',
            'contr_broker_type',
            'county',
            'current_price',
            'date_created',
            'date_leased',
            'date_modified',
            'df_yn',
            'directions',
            'display_address_yn',
            'dom',
            'elem_school',
            'expenses_assoc',
            'expenses_ins',
            'expenses_maint',
            'expenses_mgmt',
            'expenses_other',
            'expenses_tax',
            'expenses_utility',
            'expire_date',
            'flood_plain',
            'ftr_building',
            'ftr_building_type',
            'ftr_closing',
            'ftr_cooling',
            'ftr_docs_on_file',
            'ftr_exterior',
            'ftr_financing',
            'ftr_flooring',
            'ftr_heating',
            'ftr_interior',
            'ftr_internet',
            'ftr_lease_terms',
            'ftr_property_desc',
            'ftr_roof',
            'ftr_sale_terms',
            'ftr_sewer',
            'ftr_showing',
            'ftr_sprinkler',
            'ftr_style',
            'ftr_utilities',
            'ftr_utilities_rental',
            'ftr_water',
            'geo_precision',
            'georesult',
            'high_school',
            'hoa_fee',
            'hoa_fee_yn',
            'hoa_term',
            'income_gross',
            'income_net',
            'income_other',
            'income_rental',
            'internet_yn',
            'la_code',
            'leased_through',
            'legal_block',
            'legal_lot',
            'legals',
            'list_date',
            'list_price',
            'listing_type',
            'lo_code',
            'lockbox_yn',
            'lot_dimensions',
            'lot_dimensions_source',
            'media_flag',
            'middle_school',
            'mls_acct',
            'municipality',
            'num_units',
            'num_units_occupied',
            'off_mkt_date',
            'off_mkt_days',
            'office_notes',
            'orig_lp',
            'other_fee',
            'other_fee_type',
            'owner_name',
            'owner_phone',
            'parcel_id',
            'pending_date',
            'photo_count',
            'photo_date_modified',
            'photo_description',
            'photo_instr',
            'posession',
            'price_change_date',
            'price_sqft',
            'proj_close_date',
            'prop_desc',
            'prop_id',
            'prop_type',
            'remarks',
            'road_frontage_ft',
            'sa_code',
            'sale_lease',
            'sale_notes',
            'so_code',
            'sold_date',
            'sold_price',
            'sold_terms',
            'sqft_source',
            'state',
            'status',
            'status_date',
            'status_flag',
            'street',
            'street_dir',
            'street_name',
            'street_num',
            'sub_agent',
            'sub_agent_type',
            'sub_area',
            'subdivision',
            'take_photo_yn',
            'third_party_comm_yn',
            'tot_heat_sqft',
            'tour_date',
            'tour_submit_date',
            'type_detailed',
            'u1_dims',
            'u1_free_standing_yn',
            'u1_sqft_manuf',
            'u1_sqft_office',
            'u1_sqft_retail',
            'u1_sqft_total',
            'u1_sqft_warehouse',
            'u1_year_built',
            'u2_dims',
            'u2_free_standing_yn',
            'u2_sqft_manuf',
            'u2_sqft_office',
            'u2_sqft_retail',
            'u2_sqft_total',
            'u2_sqft_warehouse',
            'u2_year_built',
            'u3_dims',
            'u3_free_standing_yn',
            'u3_sqft_manuf',
            'u3_sqft_office',
            'u3_sqft_retail',
            'u3_sqft_total',
            'u3_sqft_warehouse',
            'u3_year_built',
            'unit_num',
            'upload_source',
            'vacancy_rate',
            'vacant_yn',
            'valuation_yn',
            'vt_yn',
            'waterfront_yn',
            'withdrawn_date',
            'year_built',
            'zip',
            'zoning_northport',
            'zoning_tusc'
            property[name.to_sym] = value
        end
      end
      resp.success = save && property.save
      render json: resp
    end
    
    # GET /admin/commercial/:mls_acct/refresh
    def admin_refresh
      p = CommercialProperty.find(params[:mls_acct])        
      RetsImporter.import("(MLS_ACCT=#{p.mls_acct})", 'Property', 'COM')
      RetsImporter.download_property_images(p)
      render :json => Caboose::StdClass.new({ 'success' => "The property's info has been updated from MLS." })
    end
  
  end
end
