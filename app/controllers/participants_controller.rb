require './lib/country_filter'

class ParticipantsController < ApplicationController
  before_action:authenticate_user!, :except => [:new, :create, :confirm, :certificate, :payuco_confirmation, :payuco_response]

  STATUS_LIST= [["Nuevo", "N"], ["Contactado", "T"], ["Confirmado", "C"], ["Presente", "A"],["Certificado", "K"], ["Cancelado", "X"], ["Pospuesto", "D"]]
  # GET /participants
  # GET /participants.json
  def index
    @event = Event.find(params[:event_id])
    @participants = @event.participants.sort_by(&:status_sort_order)
    @influence_zones = InfluenceZone.all
    @status_valuekey= STATUS_LIST
    @status_keyvalue= STATUS_LIST.map {|s| [s[1],s[0]]}

    respond_to do |format|
      format.html # index.html.erb
      format.csv { render :csv => @participants, :filename => "participantes_event_#{@event.id}.csv" }
      format.json { render json: @participants }
    end
  end

  def survey
    @event = Event.find(params[:event_id])
    @participants = @event.participants.attended.sort_by{ |e| [ e.fname, e.lname ]}

    respond_to do |format|
      format.html # survey.html.erb
    end
  end

  def print
    @event = Event.find(params[:event_id])
    @participants = @event.participants.confirmed_or_attended.sort_by(&:lname)

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
    session[:payment_on_eventer] = params[:payment_on_eventer] ? true : false
    @influence_zones = InfluenceZone.all.sort {|a,b| a.display_name.sub('Republica ','') <=> b.display_name.sub('Republica ','')}
    @nakedform = !params[:nakedform].nil?
    if params[:lang].nil? or params[:lang].downcase == "es"
      I18n.locale=:es
    else
      I18n.locale=:en
    end

    utm_campaign = params[:utm_campaign]
    utm_source = params[:utm_source]
    utm_campaign = utm_campaign.downcase unless utm_campaign.nil?
    utm_source = utm_source.downcase unless utm_source.nil?

    if !@event.nil?
      source = CampaignSource.where(codename: utm_source).first_or_create
      campaign = Campaign.where(codename: utm_campaign).first_or_create

      begin
        CampaignView.create( campaign: campaign, campaign_source: source, event: @event, event_type: @event.event_type, element_viewed: "registration_form" )
      rescue Exception
        puts "Sometimes a DB locked error: we can skip this record"
      end
    end

    respond_to do |format|
        format.html { render :layout => "empty_layout"}
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
    @status_valuekey= STATUS_LIST
  end

  # POST /participants
  # POST /participants.json
  def create
    @event = Event.find(params[:event_id])
    @influence_zones = InfluenceZone.all
    @participant = Participant.new(participant_params)
    @participant.event = @event
    if verify_recaptcha

      @nakedform = !params[:nakedform].nil?
      if @event.list_price == 0.0
        @participant.confirm!
      end

      utm_campaign = params[:utm_campaign]
      utm_source = params[:utm_source]
      utm_campaign = utm_campaign.downcase unless utm_campaign.nil?
      utm_source = utm_source.downcase unless utm_source.nil?
      source = CampaignSource.where(codename: utm_source).first_or_create
      campaign = Campaign.where(codename: utm_campaign).first_or_create

      respond_to do |format|
        if @participant.save
          @participant.update_attribute( :campaign_source, source)
          @participant.update_attribute( :campaign, campaign)
          if @event.list_price != 0.0
            @participant.contact!
            @participant.save
          end

          if @event.should_welcome_email and !session[:payment_on_eventer]
            EventMailer.delay.welcome_new_event_participant(@participant)
          end

          edit_registration_link = "http://#{request.host}/events/#{@participant.event.id}/participants/#{@participant.id}/edit"
          EventMailer.delay.alert_event_monitor(@participant, edit_registration_link)

          if session[:payment_on_eventer]
            webCheckout = PayuCoWebcheckoutService.new
            @payment_data = webCheckout.prepare_webcheckout(@event, @participant)
            format.html { render action: "confirm_with_payment", :layout => "empty_layout"}
          else
            format.html { redirect_to "/events/#{@event.id.to_s}/participant_confirmed#{@nakedform ? "?nakedform=1" : ""}", notice: "Tu pedido fue realizado exitosamente." }
            format.json { render json: @participant, status: :created, location: @participant }
          end

        else
          format.html { render action: "new", :layout => "empty_layout" }
          format.json { render json: @participant.errors, status: :unprocessable_entity }
        end
      end
    else
      #invalid captcha
      @captcha_error = true
      render :action => 'new',:layout => "empty_layout"
    end

  end

  # POST events/payuco_confirmation
  def payuco_confirmation
    payu_co_confirmation_service = PayuCoConfirmationService.new params
    payu_co_confirmation_service.confirm
    render status: 200, json: "ok"
  rescue Exception => e
    puts "error #{e.message}"
    puts e.backtrace
    render status: 500, json: 'error'
  end

  # GET events/payuco_response
  def payuco_response
    @data_to_show = PayuCoResponseService.new(params).response
    respond_to do |format|
      format.html { render :layout => "empty_layout" }
    end
  end

  # PUT /participants/1
  # PUT /participants/1.json
  def update
    @participant = Participant.find(params[:id])
    @influence_zones = InfluenceZone.all
    respond_to do |format|
      original_participant_status = @participant.status
      if @participant.update_attributes(participant_params)
        new_participant_status = participant_params[:status]
        @event = Event.find(params[:event_id])
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
    @participant = Participant.find(params[:id])
    @is_download = ('true' == params[:download] )
    
    error_msg=  ParticipantsHelper::validate_page_size(@page_size) ||
    ParticipantsHelper::validate_event(@participant.event) ||
    ParticipantsHelper::validation_participant(@participant, @verification_code)
    
    if error_msg.present?
      flash[:alert] = error_msg
      redirect_to event_participants_path
    else
      @certificate_store= FileStoreService.createS3
      begin
        @certificate = ParticipantsHelper::Certificate.new(@participant)
        render
      rescue ArgumentError, ActionView::Template::Error => e
        flash[:alert] = e.message
        redirect_to event_participants_path
      end
    end
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

  def search
    searching= params[:name]
    @participants= Participant.search searching
    if @participants.count == 0
      flash[:notice] = "No encontré '#{searching}'"
    end
    respond_to do |format|
      format.html # search.html.erb
    end
  end

  # GET /participants/followup
  def followup
    @active_menu = "dashboard"
    # country_filter= CountryFilter.new(params[:country_iso], session[:country_filter])
    # session[:country_filter]= @country= country_filter.country_iso

    @events = Event.public_and_visible.select{ |ev|
      !ev.event_type.nil? #&& ev.registration_link == "" && country_filter.select?(ev.country_id)
      }
    @participants=[]
    @event_names= {}
    @events.each do |event|
      @participants += event.participants.contacted
      @event_names[event.id] = event.event_type.name + " - " + event.date.to_formatted_s(:short)
    end

    # @participants = Participant.contacted.sort_by(&:updated_at)
    @participants.sort_by(&:updated_at)
    @influence_zones = InfluenceZone.all
    @status_valuekey= STATUS_LIST
    @status_keyvalue= STATUS_LIST.map {|s| [s[1],s[0]]}

    respond_to do |format|
      format.html # followup.html.erb
    end
  end

  private

  def participant_params
    params.require(:participant).permit :email, :fname, :lname, :phone, :event_id,
    :status, :notes, :influence_zone_id, :influence_zone,
    :referer_code, :promoter_score, :event_rating, :trainer_rating, :trainer2_rating, :testimony,
    :xero_invoice_number, :xero_invoice_reference, :xero_invoice_amount, :is_payed, :payment_type,
    :campaign_source, :campaign, :accept_terms, :id_number, :address
  end
    

end
