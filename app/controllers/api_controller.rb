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

  def participants_synch
    api_token_provided = params[:api_token]
    api_password_provided = params[:api_password]
    keventer_api_token = ENV["KEVENTER_API_TOKEN"]
    keventer_api_password = ENV["KEVENTER_API_PASSWORD"]

    @authorized_call = (api_token_provided == keventer_api_token) && (api_password_provided == keventer_api_password)
    @event = nil
    @participant = nil

    if @authorized_call

      course_codename = params[:course_codename]
      cohort_codename = params[:cohort_codename]
      participant_email = params[:participant_email]
      participant_fname = params[:participant_fname]
      participant_lname = params[:participant_lname]
      status = params[:status]
      po_number = params[:po_number]

      @event = Event.where("online_course_codename = ? AND online_cohort_codename = ?", course_codename, cohort_codename).first
      if !@event.nil?
        @participant = @event.participants.where("email = ?", participant_email ).last

        if @participant.nil?
          @participant = @event.participants.create( :email => participant_email, :fname => participant_fname, :lname => participant_lname)
        end

        if status == "KONLINE_NEW"
          @participant.status = Participant::STATUS[:new]
        elsif status == "KONLINE_PURCHASED"
          @participant.status = Participant::STATUS[:confirmed]
        end

        @participant.konline_po_number = po_number
        @participant.save!
      end
    end

    render :layout => false

  end

end
