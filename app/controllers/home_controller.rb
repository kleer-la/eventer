# frozen_string_literal: true

class HomeController < ApplicationController

  def catalog
    open = Event.public_and_visible.where(draft: false, cancelled: false).order('date').reduce([]) do |list, ev|
      et = ev.event_type
      list << {
        event_id: ev.id,
        date: ev.date,
        finish_date: ev.finish_date,
        city: ev.city,
        specific_subtitle: ev.specific_subtitle,
        country_name: ev.country.name,
        country_iso: ev.country.iso_code,
        list_price: ev.list_price, 
        event_duration: ev.duration,
        eb_price: ev.eb_price, 
        eb_end_date: ev.eb_end_date, 
        is_sold_out: ev.is_sold_out,
        start_time: ev.start_time , 
        end_time: ev.end_time,
        mode: ev.mode, 
        time_zone_name: ev.time_zone_name,
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
                select {|et| (open.find { |ev| ev[:event_type_id] == et.id}).nil?}.
                reduce([]) do |list, et|
      list << {
        event_id: nil,
        date: nil,
        finish_date: nil,
        city: nil,
        specific_subtitle: nil,
        country_name: nil,
        country_iso: nil,
        event_duration: nil,
        eb_price: nil,
        eb_end_date: nil,
        is_sold_out: nil,
        start_time: nil,
        end_time: nil,
        mode: nil,
        time_zone_name: nil,
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
      format.json { render json: event_type_to_json(@event_type) }
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

  def show_event_type_testimonies
    event_type = EventType.find(params[:id])
    participants = event_type.testimonies.sort_by(&:created_at).reverse.reject {|t|t['testimony']==''}

    respond_to do |format|
      format.json { render json: participants.first(10) }
    end
  end

  # json used in v2022 landing
  def event_type_to_json(event_type)
    event_type.to_json(
      only: [:id, :name, :description, :recipients, :program, :created_at, :updated_at, :goal, 
      :duration, :faq, :elevator_pitch, :learnings, :takeaways, :subtitle, :csd_eligible, :is_kleer_certification, 
      :external_site_url, :deleted, :noindex, :lang, :cover], 
      methods: %i[slug canonical_slug], include: :categories )
  
    # "id": 1,
    # "name": "Introducción a los Métodos Ágiles ",
    # "description": "Esta jornada recorre la situación general de la industria de software hasta finales del siglo XX, y el surgimiento del movimiento que culminaría en el Manifiesto Ágil, sentando los valores y principios de las metodologías ágiles.\r\nEl curso deja espacio para la discusión de estos principios a fin de que los asistentes puedan comprender en profundidad cuáles son los puntos principales de cambio y que se despejen dudas y algunos errores comunes sobre el movimiento.\r\nFinalmente se recorren las principales vertientes metodológicas y sus características principales, separando dónde pone cada una su foco y qué es lo que dejan fuera de su alcance.",
    # "recipients": "- Líderes de Equipo\r\n- Project Managers\r\n- Consultores\r\n- Integrantes de equipos de trabajo interesados en mejorar (Desarrolladores, Analistas, Diseñadores, etc).",
    # "program": "- Problemas recurrentes en la industria de software\r\n- Manifiesto Ágil\r\n    - Principios y Valores\r\n    - Metodologías más populares\r\n- Scrum\r\n- XP\r\n- Lean / Kanban\r\n- Crystal, FDD, Agile UP y otras\r\n    - Discusión de casos y alternativas con los asistentes",
    # "created_at": "2012-08-23T20:44:48.360Z",
    # "updated_at": "2022-06-29T18:53:44.036Z",
    # "goal": "Los asistentes tendrán una perspectiva general sobre los métodos ágiles, su motivación histórica y los principios generales sobre los que están basados. También conocerán los principales métodos, para poder decidir cuáles resultan más apropiados para su contexto, a fin de profundizar en ellos a través de lecturas u otros entrenamientos especializados.",
    # "duration": 4,
    # "faq": "",
    # "elevator_pitch": "Esta jornada recorre la situación general de la industria de software hasta finales del siglo XX",
    # "learnings": "",
    # "takeaways": "",
    # "subtitle": "",
    # "csd_eligible": false,
    # "is_kleer_certification": false,
    # "external_site_url": "",
    # "canonical_id": 268, -> canonical (string)
    # "deleted": true,
    # "noindex": false,
    # "lang": "es",
    # "cover": ""

    # trainers (prox evento o los del tipo de evento) - gravatar / bio(lang) / nombre / usr tw / linkedin / credential
    # events (proximos) - mismo que catálogo
    # testimonies (limite 10 - futuro solo seleccionados)
    # event_types misma categoria (todas) - mismo que catálogo

    
    # "materials": "",
    # "include_in_catalog": false,
    # "tag_name": "",
    # "average_rating": "4.61",
    # "net_promoter_score": 67,
    # "surveyed_count": 18,
    # "promoter_count": 12,
    # "cancellation_policy": "",
    # "kleer_cert_seal_image": "",

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
