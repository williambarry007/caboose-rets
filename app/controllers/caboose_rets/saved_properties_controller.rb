module CabooseRets  
  class SavedPropertiesController < ApplicationController

    # GET /saved-properties
    def index
      return if !verify_logged_in
      @properties = SavedProperty.where(:user_id => logged_in_user.id).all
    end

    # POST /saved-properties
    def add
      return if !verify_logged_in

      resp = Caboose::StdClass.new

      if SavedProperty.exists?(:user_id => logged_in_user.id, :mls => params[:mls])
        resp.success = true
      else
        p = SavedProperty.new(
          :user_id  => logged_in_user.id,
          :mls => params[:mls]
        )
        if p.save
          resp.success = true
        else
          resp.error = "There was an error saving your property."
        end
      end
      render :json => resp
    end

    # DELETE /saved-properties/:mls
    def delete
      return if !verify_logged_in
      SavedProperty.where(:user_id => logged_in_user.id, :mls => params[:mls]).destroy_all
      render :json => Caboose::StdClass.new('success' => true)
    end

    # POST /saved-properties
    def add
      return if !verify_logged_in

      resp = Caboose::StdClass.new

      if SavedProperty.exists?(:user_id => logged_in_user.id, :mls => params[:mls])
        resp.success = true
      else
        p = SavedProperty.new(
          :user_id  => logged_in_user.id,
          :mls => params[:mls]
        )
        if p.save
          resp.success = true
        else
          resp.error = "There was an error saving your property."
        end
      end
      render :json => resp
    end

    # GET /saved-properties/:mls/toggle
    def toggle_save
      return if !verify_logged_in

      resp = Caboose::StdClass.new
      if SavedProperty.where(:user_id => logged_in_user.id, :mls => params[:mls]).exists?
        SavedProperty.where(:user_id => logged_in_user.id, :mls => params[:mls]).destroy_all
        resp.saved = false
      else
        p = SavedProperty.new
        p.user_id = logged_in_user.id
        p.mls = params[:mls]
        p.save
        resp.saved = true
      end

      render :json => resp
    end

    # GET /saved-properties/:mls/status
    def status
      return if !verify_logged_in

      resp = Caboose::StdClass.new
      resp.saved = SavedProperty.where(:user_id => logged_in_user.id, :mls => params[:mls]).exists?
      render :json => resp
    end

  end
end
