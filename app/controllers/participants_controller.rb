# encoding: utf-8

class ParticipantsController < ApplicationController
  before_filter :authenticate_user!, :except => [:new, :create, :confirm, :certificate, :payuco_confirmation]

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
    @influence_zones = InfluenceZone.all
    @influence_zones.sort! {|a,b| a.display_name.sub('Republica ','') <=> b.display_name.sub('Republica ','')}
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
  end

  # POST /participants
  # POST /participants.json
  def create
    @event = Event.find(params[:event_id])
    @influence_zones = InfluenceZone.all
    @participant = Participant.new(params[:participant])
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

            if @event.mailchimp_workflow
              mailchimp_service = MailChimpService.new
              mailchimp_service.subscribe_email_to_workflow_using_automation_workflow_list @event.mailchimp_workflow_call, @participant
            end

            if @event.should_welcome_email and !session[:payment_on_eventer]
              EventMailer.delay.welcome_new_event_participant(@participant)
            end

            edit_registration_link = "http://#{request.host}/events/#{@participant.event.id}/participants/#{@participant.id}/edit"
            EventMailer.delay.alert_event_monitor(@participant, edit_registration_link)

          end


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
    logger.info "error #{e.message}"
    logger.info e.backtrace
    render status: 500, json: 'error'
  end

  # GET events/payuco_confirmation
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
      participant_parameter = params[:participant]
      if @participant.update_attributes(participant_parameter)
        new_participant_status = participant_parameter[:status]
        @event = Event.find(params[:event_id])
        if @event.mailchimp_workflow_for_warmup && new_participant_status == "C" && new_participant_status != original_participant_status
          mailChimp_service = MailChimpService.new
          mailChimp_service.subscribe_email_to_workflow_using_automation_workflow_list @event.mailchimp_workflow_for_warmup_call, @participant
        end
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
    @certificate = ParticipantsHelper::Certificate.new(@participant)

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

end
