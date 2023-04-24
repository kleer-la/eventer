# frozen_string_literal: true

require './lib/country_filter'

class ParticipantsController < ApplicationController
  before_action :authenticate_user!,
                except: %i[new create confirm certificate]

  STATUS_LIST = [%w[Nuevo N], %w[Contactado T], %w[Confirmado C], %w[Presente A], %w[Certificado K],
                 %w[Cancelado X], %w[Pospuesto D]].freeze

  def self.update_payment_status(invoice_id, xero_service = nil)
    return unless invoice_id.present?

    xero =  XeroClientService::XeroApi.new(xero_service || XeroClientService.create_xero)
    participant = Participant.search_by_invoice invoice_id
    return if participant.nil? || participant.paid?

    if xero.invoice_paid?(invoice_id)
      EventMailer.delay.participant_paid(participant)
      participant.notes << "\n#{DateTime.now.localtime} - Pagado"
      participant.paid!
      participant.save!
    elsif !participant.cancelled? && xero.invoice_void?(invoice_id)
      EventMailer.delay.participant_voided(participant)
      participant.notes << "\n#{DateTime.now.localtime} - Voided"
      participant.cancelled!
      participant.save!
    end
  end

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

  def copy
    original = Participant.find(params[:id])

    qty = [1, original.quantity - 1].max
    original.quantity = 1
    original.save!

    qty.times { original.dup.save! }

    redirect_to polymorphic_path([original.event]) + '/participants'
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

  # no route for this
  # GET /participants/1
  # GET /participants/1.json
  # def show
  #   @participant = Participant.find(params[:id])

  #   respond_to do |format|
  #     format.html
  #     format.json { render json: @participant }
  #   end
  # end

  def campaign_new
    utm_campaign = params[:utm_campaign]
    utm_source = params[:utm_source]
    utm_campaign = utm_campaign.downcase unless utm_campaign.nil?
    utm_source = utm_source.downcase unless utm_source.nil?

    return if @event.nil?

    source = CampaignSource.where(codename: utm_source).first_or_create
    campaign = Campaign.where(codename: utm_campaign).first_or_create

    begin
      CampaignView.create(campaign: campaign, campaign_source: source, event: @event, event_type: @event.event_type,
                          element_viewed: 'registration_form')
    rescue StandardError
      puts 'Sometimes a DB locked error: we can skip this record'
    end
  end

  # GET /participants/new
  # GET /participants/new.json
  def new
    @event = Event.find(params[:event_id])
    

    if @event.cancelled || @event.draft
      redirect_to "/events/#{@event.id}/participant_confirmed?cancelled=1#{@nakedform ? '&nakedform=1' : ''}",
      notice: 'No es posible registrarse a ese evento. Puedes buscar los eventos disponibles en la <a href="https://kleer.la/es/agenda">agenda</a>'
      return
    end
    if !ENV['RECAPTCHA_SITE_KEY'].present?
      redirect_to "/events/#{@event.id}/participant_confirmed?cancelled=1#{@nakedform ? '&nakedform=1' : ''}",
      notice: 'An unexpected problem just happen! Our bad!. Please contact info@kleer.la saying that "Enviroment not properly set."'
      return
    end
    @participant = Participant.new
    @influence_zones = InfluenceZone.sort_wo_republica
    @nakedform = !params[:nakedform].nil?
    I18n.locale = (:es if params[:lang].nil? || params[:lang].downcase == 'es') || :en
    @quantities = quantities_list
    campaign_new
    respond_to do |format|
      format.html { render layout: 'empty_layout' }
      format.json { render json: @participant }
    end
  end

  # [["1 personas x 100usd = 100usd", 1], ["2 personas x 100usd = 200usd", 2]]
  def quantities_list
    seat_text = []
    5.times {seat_text.push I18n.t('formtastic.button.participant.seats') }
    seat_text.push I18n.t('formtastic.button.participant.seat')

    (1..6).reduce([]) do |ac, qty|
      price = @event.price(qty, DateTime.now)
      ac << ["#{qty} #{seat_text.pop} x #{price} usd = #{price * qty} usd", qty]
    end
  end

  # GET /participants/new/confirm
  def confirm
    @event = Event.find(params[:event_id])
    I18n.locale = @event.event_type.lang.to_sym
    @nakedform = !params[:nakedform].nil?
    @cancelled = !params[:cancelled].nil?

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

  def pre_campaign(params)
    utm_campaign = params[:utm_campaign]
    utm_source = params[:utm_source]
    utm_campaign = utm_campaign.downcase unless utm_campaign.nil?
    utm_source = utm_source.downcase unless utm_source.nil?
    source = CampaignSource.where(codename: utm_source).first_or_create
    campaign = Campaign.where(codename: utm_campaign).first_or_create

    [source, campaign]
  end

  def create_mails
    if @event.should_welcome_email
      EventMailer.delay.welcome_new_event_participant(@participant)
    end

    edit_registration_link = "http://#{request.host}/events/#{@participant.event.id}/participants/#{@participant.id}/edit"
    EventMailer.delay.alert_event_monitor(@participant, edit_registration_link)
  end

  # POST /participants
  # POST /participants.json
  def create
    @event = Event.find(params[:event_id])
    @influence_zones = InfluenceZone.all
    @participant = Participant.new(participant_params)
    @participant.event = @event
    @quantities = quantities_list
    unless verify_recaptcha(model: @participant)
      # invalid captcha
      @captcha_error = true
      return render action: 'new', layout: 'empty_layout'
    end

    I18n.locale = @event.event_type.lang.to_sym

    @nakedform = !params[:nakedform].nil?
    @participant.confirm! if @event.list_price > 0.0

    source, campaign = pre_campaign(params)

    respond_to do |format|
      if @participant.save
        @participant.update_attribute(:campaign_source, source)
        @participant.update_attribute(:campaign, campaign)
        if @event.list_price > 0.0
          @participant.contact!
          @participant.save
        end
        create_mails

        format.html do
          redirect_to "/events/#{@event.id}/participant_confirmed#{@nakedform ? '?nakedform=1' : ''}",
                      notice: t('flash.participant.buy.success')
        end
        format.json { render json: @participant, status: :created, location: @participant }
      else
        format.html { render action: 'new', layout: 'empty_layout' }
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
      # original_participant_status = @participant.status
      if @participant.update(participant_params)
        # new_participant_status = participant_params[:status]
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

  def certificate_validate
    ParticipantsHelper.validate_page_size(@page_size) ||
      ParticipantsHelper.validate_event(@participant.event) ||
      ParticipantsHelper.validation_participant(@participant, @verification_code)
  end

  def certificate_error(msg)
    flash[:alert] = msg
    redirect_to event_participants_path
  end

  def render_certificate
    I18n.with_locale(@participant.event.event_type.lang) {
      @certificate = ParticipantsHelper::Certificate.new(@participant)
      render
    }
  rescue ArgumentError, ActionView::Template::Error => e
    certificate_error "#{e.message} (#{e.backtrace[0]})"
  end

  def certificate
    @page_size = params[:page_size]
    @verification_code = params[:verification_code]
    @participant = Participant.find(params[:id])
    @is_download = (params[:download] == 'true')

    error_msg = certificate_validate
    (return certificate_error(error_msg)) if error_msg.present?

    @certificate_store = FileStoreService.create_s3
    render_certificate
  end

  def certificate_preview
    @event = Event.new
    @event.event_type = EventType.find(params[:id])
    # @page_size = params[:page_size]
    # @verification_code = params[:verification_code]
    # @participant = Participant.find(params[:id])
    # @is_download = (params[:download] == 'true')

    # error_msg = certificate_validate
    # (return certificate_error(error_msg)) if error_msg.present?

    # @certificate_store = FileStoreService.create_s3
    # render_certificate
  
  end
  def certificate_preview_do
    @event = Event.new
    @event.event_type = EventType.find(params[:id])
    @event.trainer = Trainer.where.not(signature_image: [nil, ""]).first
    @event.country = Country.find(1)
    @event.date = Date.today
    
    @participant =  Participant.new
    @participant.event = @event
    @participant.fname = 'Camilo Leonardo'
    @participant.lname = 'Padilla Restrepo'

    @certificate_store = FileStoreService.create_s3

    I18n.with_locale(@participant.event.event_type.lang) {
      @certificate = ParticipantsHelper::Certificate.new(@participant)

      respond_to do |format|
        format.pdf do
          render pdf: "certificate", template: "participants/certificate"
        end
      end
    }
    
  end

  def batch_load
    success_loads, errored_loads, errored_lines = Participant.batch_load(
      params[:participants_batch],
      Event.find(params[:event_id]),
      InfluenceZone.find(params[:influence_zone_id]),
      params[:status]
    )

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
                  :status, :notes, :influence_zone_id, :influence_zone, :quantity,
                  :referer_code, :promoter_score, :event_rating, :trainer_rating, :trainer2_rating, :testimony, :selected,
                  :xero_invoice_number, :invoice_id, :is_payed, :photo_url, :profile_url,
                  :campaign_source, :campaign, :accept_terms, :company_name, :id_number, :address
  end
end
