require "open-uri"

module CabooseRets
  class OpenHousesController < ApplicationController
    
    # get /open-houses
    def index
      @open_houses = OpenHouse.where("open_house_type = 'PUB' and open_house_date >= '#{DateTime.now.strftime("%F")}'").reorder("open_house_date, start_time").all
    end
    
    # get /open-houses/:mls_number
    def details
      @open_houses = OpenHouse.find(params[:mls_number])
    end
    
    # get /admin/open-houses
    def admin_index
      render :layout => 'caboose/admin'      
    end
    
    # get /admin/open-houses/refresh
    def admin_refresh                  
      RetsImporter.update_helper('OpenHouse', DateTime.parse(1.month.ago.strftime('%F %T')))
      resp = Caboose::StdClass.new
      resp.success = "The open houses have been refreshed successfully."
      render :json => resp
    end

  end
end
