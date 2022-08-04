# frozen_string_literal: true

class HomeController < ApplicationController

  def catalog
    open = Event.public_and_visible.order('date').reduce([]) do |list, ev|
      et = ev.event_type
      list << {
        event_id: ev.id,
        date: ev.date,
        finish_date: ev.date,
        city: ev.date,
        specific_subtitle: ev.specific_subtitle,
        country_name: ev.country.name,
        country_iso: ev.country.iso_code,
        event_type_id: et.id,
        name: et.name,
        subtitle: et.subtitle,
        duration: et.duration,
        cover: et.cover,
        categories: et.categories.pluck(:id, :name).map { |id, name| { id: id, name: name } },
        lang: et.lang,
        slug: et.slug,
        csd_eligible: et.csd_eligible,
        is_kleer_certification: et.is_kleer_certification
      }
    end

    incompany = EventType.where(include_in_catalog: true, deleted: false).
                select {|et| open.find { |ev| ev[:event_type_id] == et.id}}.
                reduce([]) do |list, et|
      list << {
        event_id: nil,
        date: nil,
        finish_date: nil,
        city: nil,
        specific_subtitle: nil,
        country_name: nil,
        country_iso: nil,
        event_type_id: et.id,
        name: et.name,
        subtitle: et.subtitle,
        duration: et.duration,
        cover: et.cover,
        categories: et.categories.pluck(:id, :name).map { |id, name| { id: id, name: name } },
        lang: et.lang,
        slug: et.slug,
        csd_eligible: et.csd_eligible,
        is_kleer_certification: et.is_kleer_certification
        }
    end

    render json: open.to_a + incompany.to_a
  end

  def index
    @events = Event.public_courses
    respond_to do |format|
      format.html
      format.xml { render xml: @events.to_xml(include: event_data_to_include, methods: [:human_date]) }
      format.json { render json: @events.to_json(include: event_data_to_include, methods: [:human_date]) }
    end
  end

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

  def index_community
    @events = Event.public_community_visible.all(order: 'date')
    respond_to do |format|
      format.html
      format.xml { render xml: @events.to_xml(include: event_data_to_include, methods: [:human_date]) }
      format.json { render json: @events.to_json(include: event_data_to_include, methods: [:human_date]) }
    end
  end

  def show
    @event = Event.public_and_visible.find(params[:id])
    respond_to do |format|
      format.xml { render xml: @event.to_xml(include: event_data_to_include, methods: [:human_date]) }
      format.json { render json: @event.to_json(include: event_data_to_include, methods: [:human_date]) }
    end
  end

  def trainers
    @trainers = Trainer.order('country_id', 'name')
    respond_to do |format|
      format.html
      format.xml { render xml: @trainers.to_xml(include: :country) }
      format.json { render json: @trainers }
    end
  end

  def kleerers
    @trainers = Trainer.kleerer.order('country_id', 'name')
    respond_to do |format|
      format.xml { render xml: @trainers.to_xml(include: :country) }
      format.json { render json: @trainers }
    end
  end

  def categories
    @categories = Category.visible_ones
    respond_to do |format|
      format.xml { render xml: @categories.to_xml(include: { event_types: { methods: %i[slug canonical_slug] } }) }
      format.json { render json: @categories }
    end
  end

  # GET /event_types/1
  # GET /event_types/1.json
  def event_type_show
    @event_type = EventType.find(params[:id])

    respond_to do |format|
      format.json { render json: @event_type }
      format.xml { render xml: @event_type.to_xml(methods: %i[slug canonical_slug], include: :categories) }
    end
  end

  # GET /event_types
  # GET /event_types.json
  def event_type_index
    @event_types = EventType.all.sort { |p1, p2| p1.name <=> p2.name }

    respond_to do |format|
      format.json { render json: @event_types }
      format.xml { render xml: @event_types.to_xml({ include: :categories }) }
    end
  end

  def show_event_type_trainers
    @event_type = EventType.find(params[:id])

    respond_to do |format|
      format.xml { render xml: @event_type.trainers }
    end
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
