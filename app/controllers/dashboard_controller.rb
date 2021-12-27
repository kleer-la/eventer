# frozen_string_literal: true

require './lib/country_filter'

class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :activate_menu

  def index
    @active_menu = 'dashboard'
    country_filter = CountryFilter.new(params[:country_iso], session[:country_filter])
    session[:country_filter] = @country = country_filter.country_iso

    @events = Event.public_and_visible.order('date').select do |ev|
      !ev.event_type.nil? && ev.registration_link == '' && country_filter.select?(ev.country_id)
    end
    @nuevos_registros = 0
    @participantes_contactados = 0

    @events.each do |event|
      @nuevos_registros += event.participants.new_ones.count
      @participantes_contactados += event.participants.contacted.count
    end
  end

  def past_events
    # @events = Event.past_visible.all(:order => 'date desc').select{ |ev| !ev.event_type.nil? }
    @events = Event.past_visible.paginate(page: params[:page]).order('date desc') # .select{ |ev| !ev.event_type.nil? }
  end

  def pricing
    @active_menu = 'pricing'
    country_filter = CountryFilter.new(params[:country_iso], session[:country_filter])
    session[:country_filter] = @country = country_filter.country_iso

    @events = Event.public_commercial_visible.order(:date)
                   .where.not(event_type_id: nil)
                   .where(registration_link: '')
                   .select { |ev| country_filter.select?(ev.country_id) }
  end

  def funneling
    @events = Event.all(order: 'date')
    respond_to do |format|
      format.csv { render csv: @events, filename: 'funelling' }
    end
  end

  private

  def activate_menu
    @active_menu = 'dashboard'
  end
end
