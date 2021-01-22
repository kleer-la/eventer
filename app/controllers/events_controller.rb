include ActiveSupport
require './lib/country_filter'

class EventsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :activate_menu

  load_and_authorize_resource

  # GET /events
  # GET /events.json
  def index
    country_filter= CountryFilter.new(params[:country_iso], session[:country_filter])
    session[:country_filter]= @country= country_filter.country_iso

    @events = Event.visible.order('date').select{ |ev|
      country_filter.select?(ev.country_id)
      }

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @events }
    end
  end

  # GET /events/1
  # GET /events/1.json
  def show
    @event = Event.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @event }
    end
  end

  # GET /events/new
  # GET /events/new.json
  def new
    @event = Event.new
    @countries = Country.all
    @trainers = Trainer.all
    @timezones = TimeZone.all
    @currencies = Money::Currency.table

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @event }
    end
  end

  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
    @timezones = TimeZone.all
    @currencies = Money::Currency.table
    @event_type_cancellation_policy = @event.event_type.cancellation_policy
  end

  # POST /events
  # POST /events.json
  def create
    @event = Event.new(event_params)
    @timezones = TimeZone.all
    @currencies = Money::Currency.table
    
    respond_to do |format|
      if @event.save
        id= @event.id.to_s
        link= ' <a id="last_event" href="/events/'+id+'/edit">Editar</a>'
        format.html { redirect_to events_path, notice: t('flash.event.create.success')+link }
        format.json { render json: @event, status: :created, location: @event }
      else
        flash.now[:error] = t('flash.failure')
        format.html { render action: "new" }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /events/1
  # PUT /events/1.json
  def update
    @event = Event.find(params[:id])
    @timezones = TimeZone.all
    @currencies = Money::Currency.table

    respond_to do |format|
      if @event.update_attributes(event_params)
        if @event.cancelled
          format.html { redirect_to events_path, notice: t('flash.event.cancel.success') }
        else
          format.html { redirect_to events_path, notice: t('flash.event.update.success') }
        end
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    @event = Event.find(params[:id])
    @event.destroy

    respond_to do |format|
      format.html { redirect_to events_url }
      format.json { head :no_content }
    end
  end

  def push_to_crm
    @event = Event.find(params[:id])

    crm_push = CrmPushTransaction.create( :event => @event, :user => current_user )
    crm_push.delay.start!

    flash.now[:notice] = t('flash.event.pushing_to_crm')
  end

  def send_certificate
    @event = Event.find(params[:id])

    if @event.trainer.signature_image.nil? || @event.trainer.signature_image == ""
      flash.now[:alert] = t('flash.event.send_certificate.signature_failure')
    else

      @event.participants.each do |participant|
        if participant.is_present?
          participant.delay.generate_certificate_and_notify
        end
      end

      flash.now[:notice] = t('flash.event.send_certificate.success')
    end

  end

  def start_webinar
    @event = Event.find(params[:id])
  end

  def broadcast_webinar
    @event = Event.find(params[:id])
    @notifications = 0

    respond_to do |format|
      if @event.update_attributes(event_params)
        if @event.is_webinar?

          @event.start_webinar!
          @event.save

          hostname = "http://" + request.host
          port = request.port

          if port != 80
            hostname += ":" + port.to_s
          end

          @webinar_link = hostname + "/public_events/#{@event.id.to_s}/watch"

          if @event.notify_webinar_start?

            @event.participants.confirmed.each do |participant|
              @notifications += 1
              webinar_perticipant_link = @webinar_link + "/" + participant.id.to_s
              EventMailer.delay.notify_webinar_start(participant, webinar_perticipant_link)
            end
          end

          flash.now[:notice] = t('flash.event.webinar.broadcasting')
          format.html
        end
      else
        format.html { render action: "start_webinar" }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def activate_menu
    @active_menu = "events"
  end
  def event_params
    params.require(:event).permit :event_type_id, :trainer_id, :trainer2_id, :trainer3_id, :country_id, :date, :finish_date, :place, :capacity, :city, :visibility_type, :list_price,
                  :event_type, :country, :trainer, :duration,
                  :eb_price, :eb_end_date, :draft, :cancelled, :registration_link, :is_sold_out, :participants,
                  :start_time, :end_time, :sepyme_enabled, :mode, :time_zone_name, :embedded_player, :twitter_embedded_search,
                  :notify_webinar_start, :webinar_started, :currency_iso_code, :address, :custom_prices_email_text, :monitor_email,
                  :specific_conditions, :should_welcome_email, :should_ask_for_referer_code,
                  :couples_eb_price, :business_price, :business_eb_price, :enterprise_6plus_price, :enterprise_11plus_price,
                  :show_pricing, :extra_script, :mailchimp_workflow, :mailchimp_workflow_call, :mailchimp_workflow_for_warmup, :mailchimp_workflow_for_warmup_call, :banner_text, :banner_type, :registration_ends,
                  :cancellation_policy, :enable_online_payment, :online_course_codename, :online_cohort_codename, :specific_subtitle
  end
end
