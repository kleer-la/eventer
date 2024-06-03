# frozen_string_literal: true

class HomeController < ApplicationController

  def self.valid_name?(name)
    return false if name.to_s == ''
    name = name.strip
    return false if !!/^[a-z]+[A-Z]/.match(name)
    return false if !!/[a-z]+[A-Z]+[a-z]/.match(name)
    return false if name.length > 50
    true
  end
  def self.valid_message?(msg, filter = 'http://')
    return false if msg.to_s == ''
    return false if filter.split(',').map {|f| msg.include? f}.reduce(false){|r, elem| r || elem}
    true
  end
  def self.valid_email?(email)
    !!(email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
  end

  def self.valid_contact_us(name, email, context, subject, message, secret, filter)
    local_secret = ENV['CONTACT_US_SECRET'].to_s

    ('bad secret'     if local_secret != '' && local_secret != secret ) ||
    ('bad name'       unless self.valid_name?(name)) ||
    ('bad message'    unless self.valid_message?(message, filter)) ||
    ('empty email'    unless email.present?) ||
    ('invalid email'    unless self.valid_email?(email)) ||
    ('empty context'  unless context.present?) ||
    ('subject honeypot' if subject.present?)
  end

  def contact_us
    # params.from_jsonapi.permit(:name, :email, :context, :subject, :message)
    name = params[:name]
    email = params[:email]
    context = params[:context]
    subject = params[:subject]
    message = params[:message]

    error = self.class.valid_contact_us(
      name, email, context, subject, message, 
      params[:secret], Setting.get('CONTACT_US_MESSAGE_FILTER'))
    if error.present?
      Log.log(:mail, :info,  
        "Contact Us - #{error}", 
        "name:#{name} #{email} #{context}, message: #{message} // subject: #{subject}"
       )
    else
      ApplicationMailer.delay.contact_us(
        name,
        email,
        context,
        subject,
        message
      )
    end

    render json: { data: nil }, status: 200
  end

  def event_to_h(ev)
    {
      event_id: ev&.id,
      date: ev&.date,
      finish_date: ev&.finish_date,
      city: ev&.city,
      specific_subtitle: ev&.specific_subtitle,
      country_name: ev&.country&.name,
      country_iso: ev&.country&.iso_code,
      list_price: ev&.list_price,
      event_duration: ev&.duration,
      eb_price: ev&.eb_price,
      eb_end_date: ev&.eb_end_date,
      is_sold_out: ev&.is_sold_out,
      start_time: ev&.start_time,
      end_time: ev&.end_time,
      mode: ev&.mode,
      time_zone_name: ev&.time_zone_name
    }
  end

  def event_type_to_h(et)
    codeless_coupon = et.active_codeless_coupons
    {
      event_type_id: et.id,
      name: et.name,
      subtitle: et.subtitle,
      duration: et.duration,
      cover: et.cover,
      categories: et.categories.pluck(:id, :name).map { |id, name| { id: id, name: name } },
      lang: et.lang,
      slug: et.slug,
      csd_eligible: et.csd_eligible,
      is_kleer_certification: et.is_kleer_certification,
      external_site_url: et.external_site_url,
      platform: et.platform,
      percent_off: codeless_coupon ? codeless_coupon.percent_off : nil,
      coupon_icon: codeless_coupon ? codeless_coupon.icon : nil
    }
  end

  def catalog
    open = Event.public_and_visible.where(draft: false, cancelled: false).order('date').reduce([]) do |list, ev|
      et = ev.event_type
      list << event_to_h(ev).merge(event_type_to_h(et))
    end

    incompany = EventType.where(include_in_catalog: true, deleted: false)
                         .select { |et| (open.find { |ev| ev[:event_type_id] == et.id }).nil? }
                         .reduce([]) do |list, et|
      list << event_to_h(nil).merge(event_type_to_h(et))
    end

    render json: open.to_a + incompany.to_a
  end

  def index
    @events = Event.public_courses
    respond_to do |format|
      format.html
      format.xml { render xml: @events.to_xml(include: event_data_to_include, methods: [:human_date]) }
      format.json { render json: @events.to_json(include: event_data_to_include, methods: [:human_date, :coupons]) }
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
      format.json { render json: @trainers }
    end
  end

  def kleerers
    @trainers = Trainer.kleerer.order('country_id', 'name')
    respond_to do |format|
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

  # json used in v2022 landing
  def event_type_to_json(event_type)
    et = event_type.to_json(
      only: [:id, :name, :description, :recipients, :program, :created_at, :updated_at, :goal, 
      :duration, :faq, :elevator_pitch, :learnings, :takeaways, :subtitle, :csd_eligible, :is_kleer_certification, 
      :external_site_url, :deleted, :noindex, :lang, :cover, :side_image, :brochure, :new_version], 
      methods: %i[slug canonical_slug], include: [:categories, 
        next_events: {only: [
          :id, :date, :place, :city, :country_id, :list_price, :eb_price, :eb_end_date, :registration_link, 
          :is_sold_out, :duration, :start_time, :end_time, :time_zone_name, :currency_iso_code, :address, :finish_date], methods: :trainers} ])
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
