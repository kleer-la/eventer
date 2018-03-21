class ApiController < ApplicationController
  def index
    #.public_commercial_visible
    @events = Event.public_commercial_visible.all(:order => 'date')
    respond_to do |format|
      format.json { render json: @events.to_json(
                                          :only => [:id, :date, :finish_date, :city, :specific_subtitle],
                                          :methods => [:name, :country_name, :country_iso]
                                          ) }
    end
  end

end
