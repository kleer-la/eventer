require './lib/country_filter'

class DashboardController < ApplicationController
  before_filter :authenticate_user!
  before_filter :activate_menu

  def index
    @active_menu = "dashboard"
    country_filter= CountryFilter.new(params[:country_iso])
    @events = Event.public_and_visible.all(:order => 'date').select{ |ev|
      !ev.event_type.nil? && ev.registration_link == "" && country_filter.select?(ev.country_id)
      }
    @nuevos_registros = 0
    @participantes_contactados = 0

    @events.each do |event|
      @nuevos_registros += event.participants.new_ones.count
      @participantes_contactados += event.participants.contacted.count
    end

  end

  def past_events
    @events = Event.past_visible.all(:order => 'date desc').select{ |ev| !ev.event_type.nil? }
  end

  def pricing
    @active_menu = "pricing"
    country_iso= params[:country_iso]
    @events = Event.public_commercial_visible.all(:order => 'date').select{ |ev|
      !ev.event_type.nil? &&
      (country_iso.nil? || Country.find(ev.country_id).iso_code==country_iso.upcase)
      }
  end

  def countdown
    @events = Event.public_and_visible.all(:order => 'date').select{ |ev| !ev.event_type.nil? }
  end

  def funneling
    @events = Event.all(:order => 'date')
    respond_to do |format|
      format.csv { render :csv => @events, :filename => "funelling" }
    end
  end

  def ratings
    @active_menu = "ratings"

    @rating = Rating.first

    @top_5_nps_event_types = EventType.select{ |et| !et.net_promoter_score.nil? }.sort_by(&:net_promoter_score).reverse![0..4]
    @top_5_nps_trainers = Trainer.select{ |t| !t.net_promoter_score.nil? }.sort_by(&:net_promoter_score).reverse![0..4]


    @top_10_event_types = EventType.select{ |et| !et.average_rating.nil? }.sort_by(&:average_rating).reverse![0..9]
    @top_10_events = Event.select{ |e| !e.average_rating.nil? }.sort_by(&:average_rating).reverse![0..9]
    @top_10_trainers = Trainer.select{ |t| !t.average_rating.nil? }.sort_by(&:average_rating).reverse![0..9]
  end

  def calculate_rating

    Rating.delay.calculate( current_user )

    flash[:notice] = t('flash.rating.calculating')

    redirect_to dashboard_ratings_path
  end

  private

  def activate_menu
    @active_menu = "dashboard"
  end

end
