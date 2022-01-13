# frozen_string_literal: true

require './lib/country_filter'

class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :activate_menu

  def country_filter(country_params)
    country = CountryFilter.new(country_params, session[:country_filter])
    @country = session[:country_filter] = country.country_iso
    country
  end

  def index
    @active_menu = 'dashboard'
    country = country_filter(params[:country_iso])

    @events = Event.public_and_visible.order('date').select do |ev|
      !ev.event_type.nil? && ev.registration_link == '' && country.select?(ev.country_id)
    end
    @nuevos_registros, @participantes_contactados = count_new_contacted(@events)
  end

  def count_new_contacted(events)
    events.each_with_object([0, 0]) do |event, ac|
      ac[0] += event.participants.new_ones.count
      ac[1] += event.participants.contacted.count
    end
  end

  def past_events
    # @events = Event.past_visible.all(:order => 'date desc').select{ |ev| !ev.event_type.nil? }
    @events = Event.past_visible.paginate(page: params[:page]).order('date desc') # .select{ |ev| !ev.event_type.nil? }
  end

  def pricing
    @active_menu = 'pricing'
    country = country_filter(params[:country_iso])

    @events = Event.public_commercial_visible.order(:date)
                   .where.not(event_type_id: nil)
                   .where(registration_link: '')
                   .select { |ev| country.select?(ev.country_id) }
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
