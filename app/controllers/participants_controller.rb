class ParticipantsController < ApplicationController
  before_filter :authenticate_user!, :except => [:new, :create, :confirm]
  
  # GET /participants
  # GET /participants.json
  def index
    @event = Event.find(params[:event_id])
    @participants = @event.participants.sort_by(&:status_sort_order)
    
    respond_to do |format|
      format.html # index.html.erb
      format.csv { render :csv => @participants, :filename => "participantes_event_#{@event.id}.csv" }
      format.json { render json: @participants }
    end
  end

  # GET /participants/1
  # GET /participants/1.json
  def show
    @participant = Participant.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @participant }
    end
  end

  # GET /participants/new
  # GET /participants/new.json
  def new
    @participant = Participant.new
    @event = Event.find(params[:event_id])
    @influence_zones = InfluenceZone.all
    @nakedform = !params[:nakedform].nil?

    respond_to do |format|
      format.html { render :layout => "empty_layout" }
      format.json { render json: @participant }
    end
  end
  
  # GET /participants/new/confirm
  def confirm
    @event = Event.find(params[:event_id])
    @nakedform = !params[:nakedform].nil?
    
    respond_to do |format|
      format.html { render :layout => "empty_layout" }
    end
  end

  # GET /participants/1/edit
  def edit
    @participant = Participant.find(params[:id])
    @event = Event.find(params[:event_id])
    @influence_zones = InfluenceZone.all
  end

  # POST /participants
  # POST /participants.json
  def create
    @participant = Participant.new(params[:participant])
    @event = Event.find(params[:event_id])
    @participant.event = @event
    @nakedform = !params[:nakedform].nil?
    @influence_zones = InfluenceZone.all
    
    if @event.list_price == 0.0
      @participant.confirm!
    end
 
    respond_to do |format|
      if @participant.save
        
        if @event.is_webinar?
          
          if @event.webinar_started?
            
            format.html { redirect_to "/public_events/#{@event.id.to_s}/watch/#{@participant.id.to_s}" }
            
          else
            
            EventMailer.delay.welcome_new_webinar_participant(@participant)
          
          end
          
        else
          
          if @event.list_price != 0.0
            @participant.contact!
            @participant.save
          end
          
          if @event.should_welcome_email
            EventMailer.delay.welcome_new_event_participant(@participant)
          end
          
          edit_registration_link = "http://#{request.host}/events/#{@participant.event.id}/participants/#{@participant.id}/edit"
          EventMailer.delay.alert_event_monitor(@participant, edit_registration_link)
          
        end
        
        format.html { redirect_to "/events/#{@event.id.to_s}/participant_confirmed#{@nakedform ? "?nakedform=1" : ""}", notice: 'Tu pedido fue realizado exitosamente.' }
        format.json { render json: @participant, status: :created, location: @participant }
      else
        format.html { render action: "new", :layout => "empty_layout" }
        format.json { render json: @participant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /participants/1
  # PUT /participants/1.json
  def update
    @participant = Participant.find(params[:id])
    @influence_zones = InfluenceZone.all
 
    respond_to do |format|
      if @participant.update_attributes(params[:participant])
        format.html { redirect_to event_participants_path(@participant.event), notice: 'Participant was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @participant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /participants/1
  # DELETE /participants/1.json
  def destroy
    @participant = Participant.find(params[:id])
    @participant.destroy

    respond_to do |format|
      format.html { redirect_to polymorphic_path([@participant.event,@participant]) }
      format.json { head :no_content }
    end
  end
  
end
