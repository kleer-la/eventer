# frozen_string_literal: true

require './lib/country_filter'

class EventsController < ApplicationController
  include ActiveSupport
  before_action :authenticate_user!
  before_action :activate_menu

  load_and_authorize_resource

  # GET /events
  # GET /events.json
  def index
    country_filter = CountryFilter.new(params[:country_iso], session[:country_filter])
    session[:country_filter] = @country = country_filter.country_iso

    @events = Event.visible.order('date').select do |ev|
      country_filter.select?(ev.country_id)
    end

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

  def pre_edit
    @timezones = TimeZone.all
    @currencies = Money::Currency.table
    @event_types = EventType.where(deleted: false).where.not(duration: 0..1).order(:name)
  end

  # GET /events/new
  # GET /events/new.json
  def new
    @event = Event.new
    @countries = Country.all
    @trainers = Trainer.all
    pre_edit

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @event }
    end
  end
  
  def copy
    @event = Event.find(params[:id]).dup
    @event.date =  nil
    @event.finish_date =  nil
    pre_edit

    @event_type_cancellation_policy = @event.event_type.cancellation_policy

    render :new
  end

  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
    pre_edit
    @event_type_cancellation_policy = @event.event_type.cancellation_policy
  end

  # POST /events
  # POST /events.json
  def create
    @event = Event.new(event_params)
    pre_edit

    respond_to do |format|
      if @event.save
        link = " <a id=\"last_event\" href=\"/events/#{@event.id}/edit\">Editar</a>"
        format.html { redirect_to events_path, notice: t('flash.event.create.success') + link }
        format.json { render json: @event, status: :created, location: @event }
      else
        create_error(format, @event.errors, 'new')
      end
    end
  end

  def create_error(format, errors, action)
    flash.now[:error] = t('flash.failure')
    format.html { render action: action }
    format.json { render json: errors, status: :unprocessable_entity }
  end

  # PUT /events/1
  # PUT /events/1.json
  def update
    @event = Event.find(params[:id])
    pre_edit

    respond_to do |format|
      if @event.update(event_params)
        format.html do
          redirect_to events_path,
                      notice: (@event.cancelled ? t('flash.event.cancel.success') : t('flash.event.update.success'))
        end
        format.json { head :no_content }
      else
        create_error(format, @event.errors, 'edit')
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

  def send_certificate
    @event = Event.find(params[:id])

    if @event.trainer.signature_image.nil? || @event.trainer.signature_image == ''
      flash.now[:alert] = t('flash.event.send_certificate.signature_failure')
    else
      sent = 0

      @event.participants.each do |participant|
        if participant.could_receive_certificate?
          participant.delay.generate_certificate_and_notify
          sent += 1
        end
      end

      flash.now[:notice] = t('flash.event.send_certificate.success') + "Se están enviando #{sent} certificados."
    end
  end

  private

  def activate_menu
    @active_menu = 'events'
  end

  def event_params
    params.require(:event)
          .permit :event_type_id, :trainer_id, :trainer2_id, :trainer3_id, :country_id, :date, :finish_date, :place,
                  :capacity, :city, :visibility_type, :list_price, :event_type, :country, :trainer, :duration,
                  :eb_price, :eb_end_date, :draft, :cancelled, :registration_link, :is_sold_out, :participants,
                  :start_time, :end_time, :sepyme_enabled, :mode, :time_zone_name, :embedded_player,
                  :twitter_embedded_search, :currency_iso_code, :address, :custom_prices_email_text, :monitor_email,
                  :specific_conditions, :should_welcome_email, :should_ask_for_referer_code,
                  :couples_eb_price, :business_price, :business_eb_price, :enterprise_6plus_price,
                  :enterprise_11plus_price, :show_pricing, :extra_script, :specific_subtitle,
                  :mailchimp_workflow, :mailchimp_workflow_call, :mailchimp_workflow_for_warmup,
                  :mailchimp_workflow_for_warmup_call,
                  :banner_text, :banner_type, :registration_ends,
                  :cancellation_policy, :enable_online_payment, :online_course_codename, :online_cohort_codename
  end
end
