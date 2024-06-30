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
    end
  end

  # GET /event_types/1
  # GET /event_types/1.json
  def show
    @event_type = EventType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @event_type }
    end
  end

  def pre_edit
    @trainers = Trainer.sorted
    @categories = Category.sorted
    @cancellation_policy_setting = Setting.get('CANCELLATION_POLICY')
    @event_types = EventType.where(deleted: false).where.not(duration: 0..1).order(:name)

    store = FileStoreService.current
    @bkgd_imgs = self.background_list(store)
    @image_list = self.image_list(store)
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
  end

  def events
    @event_type = EventType.find(params[:id])
    @events =  @event_type.events.order(date: :desc)
  end

  def load_preview_default(param_values)
    param_values[:certificate_background_image_url] ||= @event.event_type.kleer_cert_seal_image.presence || ParticipantsHelper::DEFAULT_BACKGROUND_IMAGE
    param_values[:certificate_city] ||= 'Bogotá'
    param_values[:certificate_name] ||= 'Camilo Leonardo Padilla Restrepo'
    param_values[:certificate_date] ||= Date.today.prev_day.to_s
    param_values[:certificate_finish_date] ||= Date.today.to_s
    param_values[:certificate_new_version] ||= '1'
    param_values
  end

  def background_list(store)
    list = store.list('certificate').map {|obj| File.basename(obj.key)}
    list[0] = ''   # remove first (folder) + add empty option
    list.reject {|key| key.include?('-A4.')}
  end
  def image_list(store)
    list = store.list('image').map {|obj| obj.key}
    list.unshift ''   # add empty option
  end
  def participants 
    @event_type = EventType.find(params[:id])
    @participants = @event_type.events.includes(:participants).flat_map(&:participants)
    respond_to do |format|
      format.html { render}
      format.csv { send_data Participant.to_csv(@participants), filename: 'participants.csv' }
    end
  end
  
  def certificate_preview
    @event = Event.new
    @event.event_type = EventType.find(params[:id])
    @participant = Participant.new
    @participant.event = @event
    @certificate_values = load_preview_default(params.permit!.to_h[:event_type] || {})
    
    @page_size = 'LETTER'

    @certificate_store = FileStoreService.create_s3

    @images = self.background_list(@certificate_store)

    respond_to do |format|
      format.html {
        @trainers = Trainer.where.not(signature_image: [nil, ""])    
        
        render :certificate_preview
      }
      format.pdf {
        @event.trainer = Trainer.find(@certificate_values[:certificate_trainer1].to_i)
        @event.trainer2 = Trainer.find(@certificate_values[:certificate_trainer2].to_i) if @certificate_values[:certificate_trainer2].to_i > 0
        @event.country = Country.find( @certificate_values[:certificate_country].to_i)
        @event.date = Date.strptime @certificate_values[:certificate_date]
        @event.finish_date = Date.strptime @certificate_values[:certificate_finish_date]
        @event.mode = Country.find(@certificate_values[:certificate_country].to_i).iso_code == 'OL' ? 'ol' : 'cl'
        @event.event_type.new_version = (@certificate_values[:certificate_new_version] == '1')
        if @event.event_type.new_version
          @event.event_type.kleer_cert_seal_image = @certificate_values[:certificate_background_image_url]
        else
          @event.event_type.kleer_cert_seal_image = @certificate_values[:certificate_background_image_url].sub(/-(A4|LETTER)/, '')
        end
        @participant.attend!
        if @certificate_values[:certificate_kleer_cert] == '1'
          @event.event_type.is_kleer_certification = true
          @participant.certify!
        end
        @event.city = @certificate_values[:certificate_city]
        @participant.fname = @certificate_values[:certificate_name]
        begin
          I18n.with_locale(@participant.event.event_type.lang) do
            @certificate = ParticipantsHelper::Certificate.new(@participant)
            render
          end
        rescue Aws::Errors::MissingCredentialsError
          flash.now[:error] = 'Missing AWS credentials - call support'
          return redirect_to event_types_url
        end
      }
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
                  :kleer_cert_seal_image, :external_site_url, :canonical_id, :deleted, :noindex, :lang, :cover,
                  :side_image, :brochure, :new_version, :extra_script, :platform, :external_id
  end
end