require "open-uri"

module CabooseRets
  class OpenHousesController < ApplicationController
    
    # get /open-houses
    def index
      @open_houses = OpenHouse.where("open_house_type = 'PUB' and open_house_date > '#{DateTime.now.strftime("%F")}'").reorder("open_house_date, start_time").all
    end
    
    # get /open-houses/:id
    def details
      @open_houses = OpenHouse.find(params[:id])
    end
     
  end
end
