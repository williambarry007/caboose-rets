
module CabooseRets
  class PropertiesController < ApplicationController

    # @route GET /properties/search-options
    # q=rock quary
    def search_options
      count = params[:count_per_name] ? params[:count_per_name] : 10
      arr = SearchOption.results(params[:q], count)
      render :json => arr
    end

    # @route GET /properties
    def index
    	params[:street_num_like] = params[:street_name_like].tr('A-z', '').tr(' ', '') unless params[:street_name_like].nil?
    	unless params[:street_name_like].nil?
    		params[:street_name_like] = params[:street_name_like].tr('0-9', "")
    		until params[:street_name_like][0] != " " || params[:street_name_like] == ''
    			params[:street_name_like][0] = '' if params[:street_name_like][0].to_i == 0
    		end
    	end

      @pager = Caboose::PageBarGenerator.new(params, {
        'area'                     => '',
        'area_like'                => '',      
        'acreage_gte'              => '',
        'acreage_lte'              => '',
        'city'                     => '',
        'city_like'                => '',
        'county_or_parish'         => '',
        'county_or_parishy_like'   => '',
        'current_price_gte'        => '',
        'current_price_lte'        => '',
        'bedrooms_gte'             => '',
        'bedrooms_lte'             => '',
        'property_type'            => '',
        'property_subtype'         => '',
        'sqft_total_gte'           => '',
        'sqft_total_gte_lte'       => '',
        'neighborhood'             => '',
        'elementary_school'        => '',
        'middle_school'            => '',
        'high_school'              => '',
        'list_agent_mls_id'        => '',
        'list_office_mls_id'       => '',  
        'public_remarks_like'      => '',
        'waterfronts'              => '',
        'waterfronts_not_null'     => '',
        'lot_desc_like'            => '',
        'mls_number'               => '',
        'subdivision'              => '',
        'style'                    => '',
        'foreclosure_yn'           => '',
        'address_like'             => '',
        'street_name_like'         => '',
        'street_num_like'          => '',
        'postal_code'              => '',
        'postal_code_like'         => '',        
        'status'                   => 'Active'
      },{
        'model'           => 'CabooseRets::Property',
        'sort'            => CabooseRets::default_property_sort,
        'desc'            => false,
        'abbreviations'   => {
        'address_like'    => 'street_num_concat_street_name_like'
        },
        'skip'            => ['status'],
        'base_url'        => '/properties',
        'items_per_page'  => 10
      })

      @properties = @pager.items
      if params[:waterfronts].present?   then @properties.reject!{|p| p.waterfronts.blank?} end
      # if params[:ftr_lotdesc] == 'golf' then @properties.reject!{|p| p.ftr_lotdesc != 'golf'} end
      if params[:foreclosure_yn] then @properties.reject!{|p| p.foreclosure_yn != "Y"} end

      @saved_search = nil
      if CabooseRets::SavedSearch.exists?(:uri => request.fullpath)
        @saved_search = CabooseRets::SavedSearch.where(:uri => request.fullpath).first
      end

      @block_options = {
        :properties   => @properties,
        :saved_search => @saved_search,
        :pager        => @pager
      }
    end

    # @route GET /properties/:mls_number/details
    def details
      @property = Property.where(:mls_number => params[:mls_number]).first
      @saved = logged_in? && SavedProperty.where(:user_id => logged_in_user.id, :mls_number => params[:mls_number]).exists?
      if @property.nil?
        @mls_number = params[:mls_number]
        CabooseRets::RetsImporter.delay(:queue => 'rets').import_property(@mls_number.to_i)
        render 'properties/property_not_exists'
        return
      end

      @block_options = {
        :mls_number => params[:mls_number],
        :property => @property,
        :saved    => @saved,
  #      :agent    => @property ? @property.where(:list_agent_mls_id => @property.list_agent_mls_id).first : nil,
        :form_authenticity_token => form_authenticity_token
      }

      if @property.nil?
       @mls = params[:mls]
       CabooseRets::RetsImporter.delay(:queue => 'rets').import_property(@mls_number.to_i)
       render 'properties/property_not_exists'
       return
      end
    end

    #=============================================================================
    # Admin actions
    #=============================================================================

    # @route GET /admin/properties
    def admin_index
      return if !user_is_allowed('properties', 'view')

      @gen = Caboose::PageBarGenerator.new(params, {
          'mls_number'      => ''
      },{
          'model'    => 'CabooseRets::Property',
          'sort'     => 'mls_number',
          'desc'     => false,
          'base_url' => '/admin/properties',
          'use_url_params'  => false
      })
      @properties = @gen.items
      render :layout => 'caboose/admin'
    end

    # @route GET /admin/properties/:mls_number/edit
    def admin_edit
      return if !user_is_allowed('properties', 'edit')
      @property = Property.where(:mls => params[:mls_number]).first
      render :layout => 'caboose/admin'
    end

    # @route GET /admin/properties/:mls_number/refresh
    def admin_refresh
      return if !user_is_allowed('properties', 'edit')

      p = Property.find(params[:mls_number])
      p.delay(:queue => 'rets').refresh_from_mls

      resp = Caboose::StdClass.new
      resp.success = "The property's info is being updated from MLS. This may take a few minutes depending on how many images it has."
      render :json => resp
    end

  end
end
