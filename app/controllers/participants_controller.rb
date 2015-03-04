class ParticipantsController < ApplicationController
  before_filter :authenticate_user!, :except => [:new, :create, :confirm, :certificate]
  
  # GET /participants
  # GET /participants.json
  def index
    @event = Event.find(params[:event_id])
    @participants = @event.participants.sort_by(&:status_sort_order)
    @influence_zones = InfluenceZone.all
    
    respond_to do |format|
      format.html # index.html.erb
      format.csv { render :csv => @participants, :filename => "participantes_event_#{@event.id}.csv" }
      format.json { render json: @participants }
    end
  end

  def survey
    @event = Event.find(params[:event_id])
    @participants = @event.participants.attended
    
    respond_to do |format|
      format.html # survey.html.erb
    end
  end
  
  def print
    @event = Event.find(params[:event_id])
    @participants = @event.participants.confirmed.sort_by(&:lname)
    
    respond_to do |format|
      format.html { render :layout => "empty_layout" }
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
    if params[:lang].nil? or params[:lang] == "es" 
        I18n.locale=:es
      else
        I18n.locale=:en
    end

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
        format.json { respond_with_bip(@participant) }
      else
        format.html { render action: "edit" }
        #format.json { render json: @participant.errors, status: :unprocessable_entity }
        format.json { respond_with_bip(@participant) }
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
  
  def certificate

    @page_size = params[:page_size]
    @verification_code = params[:verification_code]

    participant = Participant.find(params[:id])
    @certificate = ParticipantsHelper::Certificate.new(participant)
  
  end

  def batch_load

    event = Event.find(params[:event_id])
    influence_zone = InfluenceZone.find( params[:influence_zone_id] )
    status = params[:status]

    success_loads = 0
    errored_loads = 0
    errored_lines = ""

    batch = params[:participants_batch]

    batch.lines.each do |participant_data_line|

      if Participant.create_from_batch_line( participant_data_line, event, influence_zone, status )
        success_loads += 1
      else
        errored_loads += 1
        if errored_lines == ""
          errored_lines += "'#{participant_data_line.strip}'"
        else
          errored_lines += ", '#{participant_data_line.strip}'"
        end
      end

    end
      

    flash[:alert] = t('flash.event.batch_load.error', :errored_loads => errored_loads, :errored_lines => errored_lines )
    flash[:notice] = t('flash.event.batch_load.success', :success_loads => success_loads)

    redirect_to event_participants_path

  end

end