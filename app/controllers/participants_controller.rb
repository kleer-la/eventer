# frozen_string_literal: true

require './lib/country_filter'

class ParticipantsController < ApplicationController
  before_action :authenticate_user!,
                except: %i[new create confirm certificate]

  STATUS_LIST = [%w[Nuevo N], %w[Contactado T], %w[Confirmado C], %w[Presente A], %w[Certificado K],
                 %w[Cancelado X], %w[Pospuesto D]].freeze
  # GET /participants
  # GET /participants.json
  def index
    @event = Event.find(params[:event_id])
    @participants = @event.participants.sort_by(&:status_sort_order)
    @influence_zones = InfluenceZone.all
    @status_valuekey = STATUS_LIST
    @status_keyvalue = STATUS_LIST.map { |s| [s[1], s[0]] }

    respond_to do |format|
      format.html # index.html.erb
      format.csv { render csv: @participants, filename: "participantes_event_#{@event.id}.csv" }
      format.json { render json: @participants }
    end
  end

  def survey
    @event = Event.find(params[:event_id])
    @participants = @event.participants.to_certify.sort_by { |e| [e.fname, e.lname] }

    respond_to do |format|
      format.html # survey.html.erb
    end
  end

  def print
    @event = Event.find(params[:event_id])
    @participants = @event.participants.attended?.sort_by(&:lname)

    respond_to do |format|
      format.html { render layout: 'empty_layout' }
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
    @influence_zones = InfluenceZone.all.sort do |a, b|
      a.display_name.sub('Republica ', '') <=> b.display_name.sub('Republica ', '')
    end
    @nakedform = !params[:nakedform].nil?
    I18n.locale = if params[:lang].nil? || (params[:lang].downcase == 'es')
                    :es
                  else
                    :en
                  end

    utm_campaign = params[:utm_campaign]
    utm_source = params[:utm_source]
    utm_campaign = utm_campaign.downcase unless utm_campaign.nil?
    utm_source = utm_source.downcase unless utm_source.nil?

    unless @event.nil?
      source = CampaignSource.where(codename: utm_source).first_or_create
      campaign = Campaign.where(codename: utm_campaign).first_or_create

      begin
        CampaignView.create(campaign: campaign, campaign_source: source, event: @event, event_type: @event.event_type,
                            element_viewed: 'registration_form')
      rescue Exception
        puts 'Sometimes a DB locked error: we can skip this record'
      end
    end

    respond_to do |format|
      format.html { render layout: 'empty_layout' }
      format.json { render json: @participant }
    end
  end

  # GET /participants/new/confirm
  def confirm
    @event = Event.find(params[:event_id])
    @nakedform = !params[:nakedform].nil?

    respond_to do |format|
      format.html { render layout: 'empty_layout' }
    end
  end

  # GET /participants/1/edit
  def edit
    @participant = Participant.find(params[:id])
    @event = Event.find(params[:event_id])
    @influence_zones = InfluenceZone.all
    @status_valuekey = STATUS_LIST
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
      @participant.confirm! if @event.list_price == 0.0

      utm_campaign = params[:utm_campaign]
      utm_source = params[:utm_source]
      utm_campaign = utm_campaign.downcase unless utm_campaign.nil?
      utm_source = utm_source.downcase unless utm_source.nil?
      source = CampaignSource.where(codename: utm_source).first_or_create
      campaign = Campaign.where(codename: utm_campaign).first_or_create

      respond_to do |format|
        if @participant.save
          @participant.update_attribute(:campaign_source, source)
          @participant.update_attribute(:campaign, campaign)
          if @event.list_price != 0.0
            @participant.contact!
            @participant.save
          end

          if @event.should_welcome_email && !session[:payment_on_eventer]
            EventMailer.delay.welcome_new_event_participant(@participant)
          end

          edit_registration_link = "http://#{request.host}/events/#{@participant.event.id}/participants/#{@participant.id}/edit"
          EventMailer.delay.alert_event_monitor(@participant, edit_registration_link)

          format.html do
            redirect_to "/events/#{@event.id}/participant_confirmed#{@nakedform ? '?nakedform=1' : ''}",
                        notice: 'Tu pedido fue realizado exitosamente.'
          end
          format.json { render json: @participant, status: :created, location: @participant }
        else
          format.html { render action: 'new', layout: 'empty_layout' }
          format.json { render json: @participant.errors, status: :unprocessable_entity }
        end
      end
    else
      # invalid captcha
      @captcha_error = true
      render action: 'new', layout: 'empty_layout'
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
        format.html do
          redirect_to event_participants_path(@participant.event), notice: 'Participant was successfully updated.'
        end
      else
        format.html { render action: 'edit' }
        # format.json { render json: @participant.errors, status: :unprocessable_entity }
      end
      format.json { respond_with_bip(@participant) }
    end
  end

  # DELETE /participants/1
  # DELETE /participants/1.json
  def destroy
    @participant = Participant.find(params[:id])
    @participant.destroy

    respond_to do |format|
      format.html { redirect_to polymorphic_path([@participant.event, @participant]) }
      format.json { head :no_content }
    end
  end

  def certificate
    @page_size = params[:page_size]
    @verification_code = params[:verification_code]
    @participant = Participant.find(params[:id])
    @is_download = (params[:download] == 'true')

    error_msg = ParticipantsHelper.validate_page_size(@page_size) ||
                ParticipantsHelper.validate_event(@participant.event) ||
                ParticipantsHelper.validation_participant(@participant, @verification_code)

    if error_msg.present?
      flash[:alert] = error_msg
      redirect_to event_participants_path
    else
      @certificate_store = FileStoreService.createS3
      begin
        @certificate = ParticipantsHelper::Certificate.new(@participant)
        render
      rescue ArgumentError, ActionView::Template::Error => e
        flash[:alert] = e.message + " (#{e.backtrace[0]})"
        redirect_to event_participants_path
      end
    end
  end

  def batch_load
    event = Event.find(params[:event_id])
    influence_zone = InfluenceZone.find(params[:influence_zone_id])
    status = params[:status]

    success_loads = 0
    errored_loads = 0
    errored_lines = ''

    batch = params[:participants_batch]

    batch.lines.each do |participant_data_line|
      if Participant.create_from_batch_line(participant_data_line, event, influence_zone, status)
        success_loads += 1
      else
        errored_loads += 1
        errored_lines += if errored_lines == ''
                           "'#{participant_data_line.strip}'"
                         else
                           ", '#{participant_data_line.strip}'"
                         end
      end
    end

    flash[:alert] = t('flash.event.batch_load.error', errored_loads: errored_loads, errored_lines: errored_lines)
    flash[:notice] = t('flash.event.batch_load.success', success_loads: success_loads)

    redirect_to event_participants_path
  end

  def search
    searching = params[:name]
    @participants = Participant.search searching
    flash[:notice] = "No encontré '#{searching}'" if @participants.count.zero?
    respond_to do |format|
      format.html # search.html.erb
    end
  end

  # GET /participants/followup
  def followup
    @active_menu = 'dashboard'

    events = Event.public_and_visible

    @participants, @event_names = filter_event_participants(events)

    @participants.sort_by!(&:updated_at)
    @influence_zones = InfluenceZone.all
    @status_valuekey = STATUS_LIST
    @status_keyvalue = STATUS_LIST.map { |s| [s[1], s[0]] }
  end

  private

  def filter_event_participants(events)
    participants = []
    event_names = {}
    events.each do |event|
      if event.date > Date.today
        participants += event.participants.contacted
        event_names[event.id] = "#{event.event_type.name} - #{event.date.to_formatted_s(:short)}"
      end
    end
    [participants, event_names]
  end

  def participant_params
    params.require(:participant)
          .permit :email, :fname, :lname, :phone, :event_id,
                  :status, :notes, :influence_zone_id, :influence_zone,
                  :referer_code, :promoter_score, :event_rating, :trainer_rating, :trainer2_rating, :testimony,
                  :xero_invoice_number, :xero_invoice_reference, :xero_invoice_amount, :is_payed, :payment_type,
                  :campaign_source, :campaign, :accept_terms, :id_number, :address
  end
end
