
module CabooseRets
  class AgentsController < ApplicationController

    # @route GET /real-estate/agents
    # @route GET /agents
    def index
      @agents = Agent.where(:office_mls_id => @site.rets_office_id).order(:sort_order).reject{ |a| (a.meta && a.meta.hide == true) }
    end

    # @route GET /real-estate/agents/:slug
    # @route GET /agents/:mls_id
    def details
      @agent = Agent.where(:mls_id => params[:mls_id], :office_mls_id => @site.rets_office_id).first if !params[:mls_id].blank?
      @agent = Agent.where(:slug => params[:slug], :office_mls_id => @site.rets_office_id).first if !params[:slug].blank?
      @listings = Property.where("list_agent_mls_id = ? OR co_list_agent_mls_id = ?",@agent.mls_id,@agent.mls_id).order('list_price desc').all
    end

    # @route GET /real-estate/agents/:slug/contact
    # @route GET /agents/:mls_id/contact
    def contact
      @agent = Agent.where(:mls_id => params[:mls_id], :office_mls_id => @site.rets_office_id).first if !params[:mls_id].blank?
      @agent = Agent.where(:slug => params[:slug], :office_mls_id => @site.rets_office_id).first if !params[:slug].blank?
    end

    #=============================================================================
    # Admin functions
    #=============================================================================

    # @route GET /admin/agents
    def admin_index
      return unless (user_is_allowed_to 'view', 'rets_agents')     
      render :layout => 'caboose/admin'       
    end

    # @route GET /admin/agents/json
    def admin_json 
      render :json => false and return if !user_is_allowed_to 'view', 'rets_agents'
      where = "(office_mls_id = '#{@site.rets_office_id}')"
      pager = Caboose::Pager.new(params, {
        'first_name_like' => '',
        'last_name_like' => ''
      }, {
        'model' => 'CabooseRets::Agent',
        'sort'  => 'last_name',
        'desc'  => 'false',
        'base_url' => '/admin/agents',
        'items_per_page' => 50,
        'additional_where' => [ (where) ],
      })
      render :json => {
        :pager => pager,
        :models => pager.items.as_json(:include => [:meta])
      } 
    end

    # @route GET /admin/agents/:id/json
    def admin_json_single
      render :json => false and return if !user_is_allowed_to 'edit', 'rets_agents'
      prop = Agent.find(params[:id])
      render :json => prop
    end

    # @route GET /admin/agents/edit-sort
    def admin_edit_sort
      if !user_is_allowed_to 'edit', 'rets_agents'
        Caboose.log("invalid permissions")
      else
        @agents = Agent.where(:office_mls_id => @site.rets_office_id).order(:sort_order).all
        render :layout => 'caboose/admin'  
      end
    end

    # @route PUT /admin/agents/update-sort
    def admin_update_sort
      resp = Caboose::StdClass.new
      if !user_is_allowed_to 'edit', 'rets_agents'
        Caboose.log("invalid permissions")
      else
        params[:agent].each_with_index do |ag, ind|
          agent = Agent.find(ag)
          agent.sort_order = ind
          agent.save
        end
        resp.success = true
      end
      render :json => resp
    end

    # @route GET /admin/agents/:id
    def admin_edit
      return unless (user_is_allowed_to 'edit', 'rets_agents')
      @agent = Agent.find(params[:id])
      @agent_meta = @agent.meta ? @agent.meta : AgentMeta.create(:la_code => @agent.matrix_unique_id) if @agent
      render :layout => 'caboose/admin'       
    end

    # @route PUT /admin/agents/:id
    def admin_update
      return unless (user_is_allowed_to 'edit', 'rets_agents')
      resp = Caboose::StdClass.new
      agent = Agent.find(params[:id])
      meta = agent.meta ? agent.meta : AgentMeta.create(:la_code => agent.matrix_unique_id)
      params.each do |k,v|
        case k
          when "bio" then meta.bio = v
          when "slug" then agent.slug = v
          when "hide" then meta.hide = v
          when "accepts_listings" then meta.accepts_listings = v
        end
      end
      agent.save
      meta.save
      resp.success = true
      render :json => resp
    end


    # @route POST /admin/agents/:id/image
    def admin_update_image
      render :json => false and return unless user_is_allowed_to 'edit', 'rets_agents'    
      resp = Caboose::StdClass.new({ 'attributes' => {} })
      agent = Agent.find(params[:id])
      meta = agent.meta ? agent.meta : AgentMeta.create(:la_code => agent.matrix_unique_id) if agent
      meta.image = params[:image]
      meta.save
      resp.attributes['image'] = { 'value' => meta.image.url(:thumb) }    
      render :text => resp.to_json
    end


  end
end
