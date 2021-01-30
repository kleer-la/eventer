class EventTypesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :activate_menu

  load_and_authorize_resource

  # GET /event_types
  # GET /event_types.json
  def index
    @event_types = EventType.all.sort{|p1,p2| p1.name <=> p2.name}

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @event_types }
      format.xml { render :xml => @event_types.to_xml( { :include => :categories } ) }
    end
  end

  # GET /event_types/1
  # GET /event_types/1.json
  def show
    @event_type = EventType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @event_type }
      format.xml { render xml: @event_type }
    end
  end

  # GET /event_types/new
  # GET /event_types/new.json
  def new
    @event_type = EventType.new
    @trainers = Trainer.sorted
    @categories = Category.sorted
    @cancellation_policy_setting = Setting.get("CANCELLATION_POLICY")

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @event_type }
    end
  end

  # GET /event_types/1/edit
  def edit
    @event_type = EventType.find(params[:id])
    @trainers = Trainer.sorted
    @categories = Category.sorted
    @cancellation_policy_setting = Setting.get("CANCELLATION_POLICY")
  end

  # POST /event_types
  # POST /event_types.json
  def create
    @event_type = EventType.new(event_type_params)
    @trainers = Trainer.sorted
    @categories = Category.sorted

    respond_to do |format|
      if @event_type.save
        id= @event_type.id.to_s
        link= ' <a id="last_event_type" href="/event_types/'+id+'/edit">Editar</a>'
        format.html { redirect_to event_types_path, notice: t('flash.event_type.create.success')+link  }
        format.json { render json: @event_type, status: :created, location: @event_type }
      else
        format.html { render action: "new" }
        format.json { render json: @event_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /event_types/1
  # PUT /event_types/1.json
  def update
    @event_type = EventType.find(params[:id])
    @trainers = Trainer.sorted
    @categories = Category.sorted

    respond_to do |format|
      if @event_type.update_attributes(event_type_params)
        format.html { redirect_to event_types_path, notice: t('flash.event_type.update.success') }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @event_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /event_types/1
  # DELETE /event_types/1.json
  def destroy
    @event_type = EventType.find(params[:id])
    @event_type.destroy

    respond_to do |format|
      format.html { redirect_to event_types_url }
      format.json { head :no_content }
    end
  end

  private

  def activate_menu
    @active_menu = "event_types"
  end

  def event_type_params
    params.require(:event_type).permit :name, :subtitle, :duration, :goal, :description, :recipients, :program, {trainer_ids: []},
                  :faq, :materials, {category_ids: []}, :events, :include_in_catalog, :elevator_pitch,
                  :learnings, :takeaways, :tag_name, :csd_eligible, :cancellation_policy, :is_kleer_certification,
                  :kleer_cert_seal_image, :external_site_url
  end
end
