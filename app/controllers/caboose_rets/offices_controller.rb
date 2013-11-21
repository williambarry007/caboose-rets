
module CabooseRets
  class OfficesController < ApplicationController  

    #=============================================================================
    # Admin functions
    #=============================================================================
    
    # GET /admin/offices
    def admin_index
      return if !user_is_allowed('offices', 'view')
        
      @gen = Caboose::PageBarGenerator.new(params, {
          'lo_code'      => '',               
          'lo_name_like' => ''      	  
        },{
      	  'model'       => 'CabooseRets::Office',
          'sort'			  => 'lo_name',
      	  'desc'			  => false,
      	  'base_url'		=> '/admin/offices'
      })
      @offices = @gen.items    
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/offices/:id/edit
    def admin_edit
      return if !user_is_allowed('offices', 'edit')    
      @office = Office.find(params[:id])      
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/offices/:id/refresh
    def admin_refresh
      office = Office.find(params[:id])        
      RetsImporter.import("(LO_LO_CODE=#{office.lo_code})", 'Office', 'OFF')
      render :json => Caboose::StdClass.new({ 'success' => "The office's info has been updated from MLS." })                
    end
  
    # GET /admin/offices/options
    def office_options
      options = [{
        'value' => '',
        'text' => '-- No Office --'
      }]
      Office.reorder('lo_name').all.each do |office|
        options << { 
          'value' => office.lo_code,
          'text'  => office.lo_name
        }
      end
      render :json => options 
    end
  
  end
end
