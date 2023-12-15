# frozen_string_literal: true

class Api::EventTypesController < ApplicationController
  def event_by_event_type
    @events = Event.public_commercial_visible.select do |event|
      event.event_type.id == params[:id].to_i
    end.sort_by(&:date)
    respond_to do |format|
      format.html
      format.xml { render xml: @events.to_xml(include: event_data_to_include, methods: [:human_date]) }
      format.json { render json: @events.to_json(include: event_data_to_include, methods: [:human_date]) }
    end
  end

  # GET /event_types/1
  # GET /event_types/1.json
  def show
    @event_type = EventType.find(params[:id])

    respond_to do |format|
      format.json { render json: event_type_to_json(@event_type) }
      format.xml { render xml: @event_type.to_xml(methods: %i[slug canonical_slug], include: :categories) }
    end
  end

  # GET /event_types
  # GET /event_types.json
  def index
    @event_types = EventType.all.sort { |p1, p2| p1.name <=> p2.name }

    respond_to do |format|
      format.json { render json: @event_types }
      format.xml { render xml: @event_types.to_xml({ include: :categories }) }
    end
  end

  def show_event_type_testimonies
    event_type = EventType.find(params[:id])
    participants = event_type.testimonies

    respond_to do |format|
      format.json { render json: participants.first(10) }
    end
  end

  # json used in v2022 landing
  def event_type_to_json(event_type)
    et = event_type.to_json(
      only: [:id, :name, :description, :recipients, :program, :created_at, :updated_at, :goal, 
      :duration, :faq, :elevator_pitch, :learnings, :takeaways, :subtitle, :csd_eligible, :is_kleer_certification, 
      :external_site_url, :deleted, :noindex, :lang, :cover, :side_image, :brochure, :new_version, :extra_script], 
      methods: %i[slug canonical_slug], include: [:categories, 
        next_events: {only: [
          :id, :date, :place, :city, :country_id, :list_price, :eb_price, :eb_end_date, :registration_link, :mode,
          :is_sold_out, :duration, :start_time, :end_time, :time_zone_name, :currency_iso_code, :address, :finish_date], methods: %i[trainers coupons]} ])
    et = "#{et[0..-2]},\"testimonies\":#{event_type.testimonies.where(selected: true).first(10).to_json(
      only: [:fname, :lname, :testimony, :profile_url, :photo_url]
    )}}"
  end

  private

  def event_data_to_include
    {
      country: {},
      event_type: { methods: %i[slug canonical_slug] },
      trainer: {},
      trainer2: {},
      trainers: {},
      categories: {}
    }
  end

end
