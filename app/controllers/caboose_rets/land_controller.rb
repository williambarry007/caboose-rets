
module CabooseRets
  class LandController < ApplicationController  
     
    # GET /land
    def index
      @gen = Caboose::PageBarGenerator.new(params, {
          'mls_acct' => ''
        },{
          'model'           => 'ResidentialProperty',
          'sort'            => 'mls_acct',
          'desc'            => false,
          'base_url'        => '/land',
          'items_per_page'  => 10
      })
      Caboose.log(@gen.where)
      @properties = @gen.items
      if params[:waterfront].present? then @properties.reject!{|p| p.waterfront.blank?} end
      if params[:ftr_lotdesc] == 'golf' then @properties.reject!{|p| p.ftr_lotdesc != 'golf'} end
      #if params[:foreclosure] then @properties.reject!{|p| p.foreclosure_yn != "Y"} end
    end
    
    # GET /land/:mls_acct/details
    def details
      @property = ResidentialProperty.where(:mls_acct => params[:mls_acct]).first
      if @property.nil?
        @mls_acct = params[:mls_acct]
        render 'land/land_not_exists'
        return
      end
      @message = Message.new    
    end
    
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # GET /admin/land
    def admin_index
      return if !user_is_allowed('properties', 'view')
        
      @gen = Caboose::PageBarGenerator.new(params, {
          'name'       => ''
      },{
          'model'       => 'ResidentialProperty',
          'sort'        => 'mls_acct',
          'desc'        => false,
          'base_url'    => '/admin/land'
      })
      @properties = @gen.items    
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/land/:mls_acct/edit
    def admin_edit
      return if !user_is_allowed('properties', 'edit')    
      @property = ResidentialProperty.where(:mls_acct => params[:mls_acct]).first
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/land/:mls_acct/refresh
    def admin_refresh        
      RetsLandImporter.import_property(params[:mls_acct])
      flash[:message] = "<p class='note success'>The property info has been updated from MLS.</p>"
      render :json => Caboose::StdClass.new({ 'reload' => true })
    end
   
  end
end