
module CabooseRets
  class RetsController < ApplicationController
    
    # GET /admin/rets/import
    def admin_import_form
      return if !user_is_allowed('properties', 'edit')
      render :layout => 'caboose/admin'
    end
      
    # POST /admin/rets/import
    def admin_import
      return if !user_is_allowed('properties', 'edit')
                  
      mls_acct = params[:mls_acct].to_i            
      ResidentialProperty.delay.import_from_mls(mls_acct)        
      
      resp = Caboose::StdClass.new
      resp.success = "The property is being imported from MLS.  This may take a few minutes depending on how many images it has."
      render :json => resp
    end

  end
end
