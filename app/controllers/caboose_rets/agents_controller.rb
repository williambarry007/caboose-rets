
module CabooseRets
  class AgentsController < ApplicationController

    # @route GET /agents
    def index
      @agents = Agent.where(:office_mls_id => @site.rets_office_id).order(:sort_order).reject{ |a| (a.meta && a.meta.hide == true) }
    end

    # @route GET /agents/:mls_id
    def details
      @agent = Agent.where(:mls_id => params[:mls_id]).first
    end

    #=============================================================================
    # Admin functions
    #=============================================================================

    # @route GET /admin/agents
    def admin_index
      return unless (user_is_allowed_to 'view', 'agents')     
      render :layout => 'caboose/admin'       
    end

    # @route GET /admin/agents/json
    def admin_json 
      render :json => false and return if !user_is_allowed_to 'view', 'agents'
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
        :models => pager.items
      } 
    end

    # @route GET /admin/agents/:id/json
    def admin_json_single
      render :json => false and return if !user_is_allowed_to 'edit', 'agents'
      prop = Agent.find(params[:id])
      render :json => prop
    end

    # @route GET /admin/agents/edit-sort
    def admin_edit_sort
      if !user_is_allowed_to 'edit', 'agents'
        Caboose.log("invalid permissions")
      else
        @agents = Agent.where(:office_mls_id => @site.rets_office_id).order(:sort_order).all
        render :layout => 'caboose/admin'  
      end
    end

    # @route PUT /admin/agents/update-sort
    def admin_update_sort
      resp = Caboose::StdClass.new
      if !user_is_allowed_to 'edit', 'agents'
        Caboose.log("invalid permissions")
      else
        pa = Agent.find(params[:pa_id])
        pa.sort_order = params[:sort_order]
        pa.save
        resp.success = true
      end
      render :json => resp
    end

    # @route GET /admin/agents/:id
    def admin_edit
      return unless (user_is_allowed_to 'edit', 'agents')
      @agent = Agent.find(params[:id])
      @agent_meta = @agent.meta ? @agent.meta : AgentMeta.create(:la_code => @agent.matrix_unique_id) if @agent
      render :layout => 'caboose/admin'       
    end

    # @route PUT /admin/agents/:id
    def admin_update
      return unless (user_is_allowed_to 'edit', 'agents')
      resp = Caboose::StdClass.new
      agent = Agent.find(params[:id])
      meta = agent.meta ? agent.meta : AgentMeta.create(:la_code => agent.matrix_unique_id)
      params.each do |k,v|
        case k
          when "bio" then meta.bio = v
          when "hide" then meta.hide = v
        end
      end
      agent.save
      meta.save
      resp.success = true
      render :json => resp
    end


    # @route POST /admin/agents/:id/image
    def admin_update_image
      render :json => false and return unless user_is_allowed_to 'edit', 'agents'    
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
