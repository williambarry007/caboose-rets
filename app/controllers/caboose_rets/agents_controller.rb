
module CabooseRets
  class AgentsController < ApplicationController  
     
    # GET /agents
    def index
      @agents     = Agent.where("lo_code = '46' AND hide IS false").order("last_name, first_name")
      @agent      = Agent.where(:la_code => '048540000').first
      @assistants = Agent.where(:assistant_to => '048540000').order("last_name, first_name")
    end
  
    # GET /agents/:la_code
    def details
      la_code = params[:la_code]
      @agents = Agent.where("lo_code = '46' AND hide IS false").order("last_name, first_name")
      @agent = Agent.where(:la_code => la_code).first || Agent.where(:la_code => '048540000').first    
      @assistants = Agent.where(:assistant_to => la_code).order("last_name, first_name")
      @next = Agent.where("\'la_code\' > \'#{la_code}\' AND \'la_code\' <> \'048540000\' AND \'lo_code\' = \'46\' AND hide IS false").order("last_name, first_name").first
      @prev = Agent.where("\'la_code\' < \'#{la_code}\' AND \'la_code\' <> \'048540000\' AND \'lo_code\' = \'46\' AND hide IS false").order("last_name, first_name").first
    end
    
    # GET /agents/:la_code/listings
    def listings
      @agent = Agent.where(:la_code => params[:la_code]).first
      is_agents = "la_code = ? AND (status = 'Active' OR status = 'Pending')"
      is_coagents = "co_la_code = ? AND (status = 'Active' OR status = 'Pending')"
  
      residential_properties = ResidentialProperty.where(is_agents, params[:la_code])
      residential_properties += ResidentialProperty.where(is_coagents, params[:la_code]).select{ |p| defined? p && p.mls_acct }
      
      commercial_properties = CommercialProperty.where(is_agents, params[:la_code])
      commercial_properties += CommercialProperty.where(is_coagents, params[:la_code]).select{ |p| defined? p && p.mls_acct }
      
      land_properties = LandProperty.where(is_agents, params[:la_code])
      land_properties += LandProperty.where(is_coagents, params[:la_code]).select{ |p| defined? p && p.mls_acct }
  
      @property_groups = [
        { type: 'RES' , title: 'Residential Listings' , url_prefix: 'residential' , properties: residential_properties },
        { type: 'COM' , title: 'Commercial Listings'  , url_prefix: 'commercial'  , properties: commercial_properties  },
        { type: 'LND' , title: 'Land Listings'        , url_prefix: 'land'        , properties: land_properties        },
      ]        
    end
    
    #=============================================================================
    # Admin functions
    #=============================================================================
    
    # GET /admin/agents
    def admin_index
      return if !user_is_allowed('agents', 'view')
        
      @gen = Caboose::PageBarGenerator.new(params, {
          'lo_code'         => '',
          'la_code'         => '',               
          'first_name_like' => '',
      	  'last_name_like'  => ''
        },{
      	  'model'       => 'CabooseRets::Agent',
          'sort'			  => 'last_name, first_name',
      	  'desc'			  => false,
      	  'base_url'		=> '/admin/agents'
      })
      @agents = @gen.items    
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/agents/:id/edit
    def admin_edit
      return if !user_is_allowed('agents', 'edit')    
      @agent = Agent.find(params[:id])
      @boss = @agent.assistant_to.nil? || @agent.assistant_to.strip.length == 0 ? nil : Agent.where(:la_code => @agent.assistant_to).first
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
          when 'assistant_to'
            agent.assistant_to = value
            if !value.nil? && value.length > 0 && Agent.exists?(:la_code => value)
              boss = Agent.where(:la_code => value).first
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
      RetsAgentsImporter.import_agent(agent.la_code)
      flash[:message] = "<p class='note success'>The agent's info has been updated from MLS.</p>"
      render :json => Caboose::StdClass.new({ 'reload' => true })
    end
  
    # GET /admin/agents/assistant-to-options
    def admin_assistant_to_options
      options = [{
        'value' => '',
        'text' => '-- Not an assistant --'
      }]
      Agent.where(:lo_code => '46').reorder('last_name, first_name').all.each do |a|
        options << {
          'value' => a.la_code,
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
      Agent.where(:lo_code => '46').reorder('last_name, first_name').all.each do |a|
        options << { 
          'value' => a.la_code,
          'text' => "#{a.first_name} #{a.last_name}"
        }
      end
      render :json => options 
    end
  
  end
end
