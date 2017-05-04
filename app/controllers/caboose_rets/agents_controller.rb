
module CabooseRets
  class AgentsController < ApplicationController

    # GET /agents
    def index
      @agents     = Agent.where("office_mls_id = '46' ").order("last_name, first_name")
      @agent      = Agent.where(:mls_id => '048540000').first
      @assistants = Agent.where(:assistant_to => '048540000').order("last_name, first_name")
    end

    # GET /agents/:mls_id
    def details
      mls_id = params[:mls_id]
      @agents = Agent.where("mls_id = '46'").order("last_name, first_name")
      @agent = Agent.where(:mls_id => mls_id).first || Agent.where(:mls_id => '048540000').first      
      # @assistants = Agent.where(:assistant_to => la_code).order("last_name, first_name")
      @next = Agent.where("\'mls_id\' > \'#{mls_id}\' AND \'mls_id\' <> \'048540000\' AND \'office_mls_id\' = \'46\'").order("last_name, first_name").first
      @prev = Agent.where("\'mls_id\' < \'#{mls_id}\' AND \'mls_id\' <> \'048540000\' AND \'office_mls_id\' = \'46\'").order("last_name, first_name").first
    end

    # GET /agents/:mls_id/listings
    def listings
      @agent = Agent.where(:mls_id => params[:mls_id]).first
      is_agents = "mls_id = ? AND status = 'Active'"
      # is_coagents = "co_la_code = ? AND status = 'Active'"

      properties = Property.where(is_agents, params[:mls_id])
      # residential_properties += Property.where(is_coagents, params[:mls_id]).select{ |p| defined? p && p.mls_acct }

      @property_groups = [
        { type: 'Listing' , title: 'Property Listings' , url_prefix: 'properties' , properties: properties }        
      ]
    end

    #=============================================================================
    # Admin functions
    #=============================================================================

    # GET /admin/agents
    def admin_index
      return if !user_is_allowed('agents', 'view')

      @gen = Caboose::PageBarGenerator.new(params, {
          'office_mls_id'   => '',
          'mls_id'          => '',
          'first_name_like' => '',
          'last_name_like'  => ''
        },{
          'model'       => 'CabooseRets::Agent',
          'sort'        => 'last_name, first_name',
          'desc'        => false,
          'base_url'    => '/admin/agents',
          'use_url_params'  => false
      })
      @agents = @gen.items
      render :layout => 'caboose/admin'
    end

    # GET /admin/agents/:id/edit
    def admin_edit
      return if !user_is_allowed('agents', 'edit')
      @agent = Agent.find(params[:id])
      @boss = @agent.assistant_to.nil? || @agent.assistant_to.strip.length == 0 ? nil : Agent.where(:mls_id => @agent.assistant_to).first
      render :layout => 'caboose/admin'
    end

    # GET /admin/agents/:id/edit-bio
    def admin_edit_bio
      return if !user_is_allowed('agents', 'edit')
      @agent = Agent.find(params[:id])
      render :layout => 'caboose/admin'
    end

    # GET /admin/agents/:id/edit-contact-info
    def admin_edit_contact_info
      return if !user_is_allowed('agents', 'edit')
      @agent = Agent.find(params[:id])
      render :layout => 'caboose/admin'
    end

    # GET /admin/agents/:id/edit-mls-info
    def admin_edit_mls_info
      return if !user_is_allowed('agents', 'edit')
      @agent = Agent.find(params[:id])
      render :layout => 'caboose/admin'
    end

    # POST /admin/agents/:id
    def admin_update
      Caboose.log(params)
      return if !user_is_allowed('agents', 'edit')

      resp = Caboose::StdClass.new({'attributes' => {}})
      agent = Agent.find(params[:id])

      save = true
      params.each do |name,value|
        case name
          when 'hide'
            agent.hide = value
          when 'contact_info'
            agent.contact_info = value
          when 'bio'
            agent.bio = value
          when 'designation'
            agent.designation = value
          when 'assistant_to'
            agent.assistant_to = value
            if !value.nil? && value.length > 0 && Agent.exists?(:mls_id => value)
              boss = Agent.where(:mls_id => value).first
              resp.attributes['assistant_to'] = { 'text' => "#{boss.first_name} #{boss.last_name}" }
            else
              resp.attributes['assistant_to'] = { 'text' => "Not an assistant" }
            end
        end
      end
      resp.success = save && agent.save
      render :json => resp
    end

    # GET /admin/agents/:id/refresh
    def admin_refresh
      agent = Agent.find(params[:id])
      RetsImporter.import("(LA_LA_CODE=#{agent.mls_id})", 'Agent', 'AGT')
      RetsImporter.download_agent_images(agent)
      render :json => Caboose::StdClass.new({ 'success' => "The agent's info has been updated from MLS." })
    end

    # GET /admin/agents/assistant-to-options
    def admin_assistant_to_options
      options = [{
        'value' => '',
        'text' => '-- Not an assistant --'
      }]
      Agent.where(:office_mls_id => '46').reorder('last_name, first_name').all.each do |a|
        options << {
          'value' => a.mls_id,
          'text' => "#{a.first_name} #{a.last_name}"
        }
      end
      render :json => options
    end

    # GET /admin/agents/agent_options
    def agent_options
      options = [{
        'value' => '',
        'text' => '-- No Agent --'
      }]
      Agent.where(:office_mls_id => '46').reorder('last_name, first_name').all.each do |a|
        options << {
          'value' => a.mls_id,
          'text' => "#{a.first_name} #{a.last_name}"
        }
      end
      render :json => options
    end

  end
end
