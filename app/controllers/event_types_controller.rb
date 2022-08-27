# frozen_string_literal: true

def lang_select(data, filter)
  !filter.present? || filter == 'all' || (data == filter)
end

def active_select(data, filter)
  !filter.present? || filter == 'all' || (data == ActiveModel::Type::Boolean.new.cast(filter) )
end

def duration_select(data, filter)
  data ||=0
  !filter.present? || filter == 'all' || (data <= 1 && filter == '1' ) || (data > 1 && filter != '1' )
end

def index_canonical_select(canonical, noindex, filter)
  filter_idx= filter.first(2) == 'ni' unless filter.nil?
  filter_can= filter.last(2) != 'nc' unless filter.nil?

  !filter.present? || filter == 'all' || (!(canonical ^ filter_can) && !(noindex ^ filter_idx))  
end

class EventTypesController < ApplicationController
  before_action :authenticate_user!
  before_action :activate_menu

  load_and_authorize_resource

  # GET /event_types
  # GET /event_types.json
  def index
    @lang = params[:lang] || session[:lang_filter]
    @lang = nil if @lang == 'all'
    session[:lang_filter] = @lang

    @active = params[:active] || session[:active_filter] || 'true'
    session[:active_filter] = @active

    @duration = params[:duration] || session[:duration_filter] || '2'
    session[:duration_filter] = @duration

    @indexcanonical = params[:indexcanonical] || session[:indexcanonical_filter]
    @indexcanonical = nil if @indexcanonical == 'all'
    session[:indexcanonical_filter] = @indexcanonical

    @event_types = EventType.all.order('name').select do |et|
      lang_select(et.lang, @lang) && 
      active_select(!et.deleted, @active) && 
      duration_select(et.duration, @duration) &&
      index_canonical_select(et.canonical.present?, et.noindex, @indexcanonical)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @event_types }
      format.xml { render xml: @event_types.to_xml({ include: :categories }) }
    end
  end

  # GET /event_types/1
  # GET /event_types/1.json
  def show
    @event_type = EventType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @event_type }
      format.xml { render xml: @event_type.to_xml(methods: [:canonical_slug]) }
    end
  end

  def pre_edit
    @trainers = Trainer.sorted
    @categories = Category.sorted
    @cancellation_policy_setting = Setting.get('CANCELLATION_POLICY')
    @event_types = EventType.where(deleted: false).where.not(duration: 0..1).order(:name)
  end

  # GET /event_types/new
  # GET /event_types/new.json
  def new
    @event_type = EventType.new
    pre_edit

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @event_type }
    end
  end

  # GET /event_types/1/edit
  def edit
    @event_type = EventType.find(params[:id])
    pre_edit
  end

  # POST /event_types
  # POST /event_types.json
  def create
    @event_type = EventType.new(event_type_params)
    pre_edit

    respond_to do |format|
      if @event_type.save
        link = " <a id=\"last_event_type\" href=\"/event_types/#{@event_type.id}/edit\">Editar</a>"
        format.html { redirect_to event_types_path, notice: t('flash.event_type.create.success') + link }
        format.json { render json: @event_type, status: :created, location: @event_type }
      else
        create_error(format, @event_type.errors, 'new')
      end
    end
  end

  def create_error(format, errors, action)
    flash.now[:error] = t('flash.failure')
    format.html { render action: action }
    format.json { render json: errors, status: :unprocessable_entity }
  end

  # PUT /event_types/1
  # PUT /event_types/1.json
  def update
    @event_type = EventType.find(params[:id])
    pre_edit

    respond_to do |format|
      if @event_type.update(event_type_params)
        format.html { redirect_to event_types_path, notice: t('flash.event_type.update.success') }
        format.json { head :no_content }
      else
        create_error(format, @event_type.errors, 'edit')
      end
    end
  end

  # DELETE /event_types/1
  # DELETE /event_types/1.json
  def destroy
    redirect_to event_types_path, notice: 'Event type delete is disable. Contact entrenamos@kleer.la'

    # @event_type = EventType.find(params[:id])
    # @event_type.destroy

    # respond_to do |format|
    #   format.html { redirect_to event_types_url }
    #   format.json { head :no_content }
    # end
  end

  def testimonies
    @event_type = EventType.find(params[:id])
    @participants = @event_type.testimonies.sort_by(&:created_at).reverse

    respond_to do |format|
      format.html
      format.json { render json: @participants.first(10) }
    end
  end

  private

  def activate_menu
    @active_menu = 'event_types'
  end

  def event_type_params
    params.require(:event_type)
          .permit :name, :subtitle, :duration, :goal, :description, :recipients, :program, { trainer_ids: [] },
                  :faq, :materials, { category_ids: [] }, :events, :include_in_catalog, :elevator_pitch,
                  :learnings, :takeaways, :tag_name, :csd_eligible, :cancellation_policy, :is_kleer_certification,
                  :kleer_cert_seal_image, :external_site_url, :canonical_id, :deleted, :noindex, :lang, :cover
  end
end
