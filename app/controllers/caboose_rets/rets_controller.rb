
module CabooseRets
  class RetsController < ApplicationController
    
    # GET /admin/rets/import
    def admin_import_form
      return if !user_is_allowed('rets_properties', 'edit')
      render :layout => 'caboose/admin'
    end
      
    # POST /admin/rets/import
    def admin_import
      return if !user_is_allowed('rets_properties', 'edit')      
      mui = params[:mls]
      CabooseRets::RetsImporter.delay(:priority => 10, :queue => 'rets').import_properties(mui, true)
      resp = Caboose::StdClass.new
      resp.success = "The property is being imported from MLS. This may take a few minutes depending on how many images it has."
      render :json => resp
    end

  end
end
