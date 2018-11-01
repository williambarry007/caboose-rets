
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
    	params[:street_number_like] = params[:street_name_like].tr('A-z', '').tr(' ', '') unless params[:street_name_like].nil?
    	unless params[:street_name_like].nil?
    		params[:street_name_like] = params[:street_name_like].tr('0-9', "")
    		until params[:street_name_like][0] != " " || params[:street_name_like] == ''
    			params[:street_name_like][0] = '' if params[:street_name_like][0].to_i == 0
    		end
    	end
      where = @site && @site.id == 558 ? "(style ILIKE '%condo%' OR res_style ILIKE '%condo%' OR property_subtype ILIKE '%condo%')" : "(id is not null)"
      sortby = @site && @site.id == 558 ? "original_entry_timestamp" : CabooseRets::default_property_sort
      @pager = Caboose::PageBarGenerator.new(params, {
        'area'                     => '',
        'area_like'                => '',      
        'acreage_gte'              => '',
        'acreage_lte'              => '',
        'city'                     => '',
        'city_like'                => '',
        'county_or_parish'         => '',
        'county_or_parishy_like'   => '',
        'list_price_gte'           => '',
        'list_price_lte'           => '',
        'beds_total_gte'           => '',
        'beds_total_lte'           => '',
        'baths_total_gte'          => '',
        'baths_total_lte'          => '',
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
        'street_number_like'          => '',
        'postal_code'              => '',
        'postal_code_like'         => '',        
        'status'                   => 'Active'
      },{
        'model'           => 'CabooseRets::Property',
        'sort'            => sortby,
        'desc'            => true,
        'abbreviations'   => {
        'address_like'    => 'street_number_concat_street_name_like'
        },
        'skip'            => ['status'],
        'base_url'        => '/properties',
        'items_per_page'  => 10,
        'additional_where' => [ where ]
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
      @agent = Agent.where(:matrix_unique_id => @property.list_agent_mui, :office_mls_id => @site.rets_office_id).first
      @saved = logged_in? && SavedProperty.where(:user_id => logged_in_user.id, :mls_number => params[:mls_number]).exists?
      if @property.nil?
        @mls_number = params[:mls_number]
      #  CabooseRets::RetsImporter.delay(:priority => 10, :queue => 'rets').import_property(@mls_number.to_i)
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
    #   CabooseRets::RetsImporter.delay(:priority => 10, :queue => 'rets').import_property(@mls_number.to_i)
       render 'properties/property_not_exists'
       return
      end
    end

    #=============================================================================
    # Admin actions
    #=============================================================================


    # @route GET /admin/properties
    def admin_index
      return unless (user_is_allowed_to 'view', 'rets_properties')     
      render :layout => 'caboose/admin'       
    end

    # @route GET /admin/properties/json
    def admin_json 
      render :json => false and return if !user_is_allowed_to 'view', 'rets_properties'
      desc = params[:desc].blank? && !params[:sort].blank? ? 'false' : 'true'
      pager = Caboose::Pager.new(params, {
        'mls_number' => ''
      }, {
        'model' => 'CabooseRets::Property',
        'sort'  => 'mls_number',
        'desc'  => desc,
        'base_url' => '/admin/properties',
        'items_per_page' => 50
      })
      render :json => {
        :pager => pager,
        :models => pager.items
      } 
    end

    # @route GET /admin/properties/:id/json
    def admin_json_single
      render :json => false and return if !user_is_allowed_to 'edit', 'rets_properties'
      prop = Property.find(params[:id])
      render :json => prop
    end

    # @route GET /admin/properties/:id
    def admin_edit
      return unless (user_is_allowed_to 'edit', 'rets_properties')
      @property = Property.find(params[:id])
      render :layout => 'caboose/admin'
    end

    # @route GET /admin/properties/:id/refresh
    def admin_refresh
      return unless (user_is_allowed_to 'edit', 'rets_properties')
      p = Property.find(params[:id])
      CabooseRets::RetsImporter.delay(:priority => 10, :queue => 'rets').import_properties(p.mls_number, true)
      resp = Caboose::StdClass.new
      resp.success = "The property's info is being updated from MLS. This may take a few minutes depending on how many images it has."
      render :json => resp
    end

    # @route GET /rets/products-feed/:fieldtype
    def facebook_products_feed
      rc = CabooseRets::RetsConfig.where(:site_id => @site.id).first
      if params[:fieldtype] == 'agent' && rc && !rc.agent_mls.blank?
        @properties = CabooseRets::Property.where("list_agent_mls_id = ?", rc.agent_mls).order("original_entry_timestamp DESC").take(100)
      elsif params[:fieldtype] == 'office' && rc && !rc.office_mls.blank?
        @properties = CabooseRets::Property.where("list_office_mls_id = ?", rc.office_mls).order("original_entry_timestamp DESC").take(100)
      else
        @properties = CabooseRets::Property.order("original_entry_timestamp DESC").take(100)
      end
      respond_to do |format|
        format.rss { render :layout => false }
      end
    end

    # @route GET /rets/listings-feed/:fieldtype
    def facebook_listings_feed
      rc = CabooseRets::RetsConfig.where(:site_id => @site.id).first
      if params[:fieldtype] == 'agent' && rc && !rc.agent_mls.blank?
        if @site.id == 558
          @properties = CabooseRets::Property.where("list_agent_mls_id in (?)", ['118593705','118511951','118598750','SCHMANDTT','118599999','118509093','118518704','118515504']).order("original_entry_timestamp DESC").take(100)
        else
          @properties = CabooseRets::Property.where("list_agent_mls_id = ?", rc.agent_mls).order("original_entry_timestamp DESC").take(100)
        end
      elsif params[:fieldtype] == 'office' && rc && !rc.office_mls.blank?
        @properties = CabooseRets::Property.where("list_office_mls_id = ?", rc.office_mls).order("original_entry_timestamp DESC").take(100)
      else
        @properties = CabooseRets::Property.order("original_entry_timestamp DESC").take(100)
      end
      respond_to do |format|
        format.rss { render :layout => false }
      end
    end

  end
end
