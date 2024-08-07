# frozen_string_literal: true

class ResourcesController < ApplicationController
  before_action :set_resource, only: %i[edit update]

  # GET /resources
  def index
    @resources = Resource.order(created_at: :desc)
  end

  # # GET /resources/1
  # def show
  #   respond_to do |format|
  #     format.html
  #     format.json { render json: @resources,
  #       methods: [:category_name],
  #       include: { trainers: { only: [:name, :bio, :bio_en, :gravatar_email, :twitter_username, :linkedin_url] } } }
  #   end
  # end

  # GET /resources/new
  def new
    @resource = Resource.new
  end

  # GET /resources/1/edit
  def edit; end

  # POST /resources
  def create
    @resource = Resource.new(resources_params)

    if @resource.save
      redirect_to edit_resource_path(@resource), notice: 'Resources was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /resources/1
  def update
    if @resource.update(resources_params)
      redirect_to edit_resource_path(@resource), notice: 'Resource was successfully updated.'
    else
      render :edit
    end
  end

  # # DELETE /resources/1
  # def destroy
  #   @resource.destroy
  #   redirect_to resources_url, notice: 'resource was successfully destroyed.'
  # end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_resource
    @resource = Resource.friendly.find(params[:id].downcase)
  end

  # Only allow a trusted parameter "white list" through.
  def resources_params
    params[:resource][:slug].downcase! if params[:resource][:slug].present?
    params.require(:resource)
          .permit(:format, :slug, :category_id, :downloadable,
                  :title_es, :description_es, :cover_es, :landing_es, :share_link_es, :share_text_es, :tags_es, :comments_es, :getit_es, :buyit_es,
                  :title_en, :description_en, :cover_en, :landing_en, :share_link_en, :share_text_en, :tags_en, :comments_en, :getit_en, :buyit_en,
                  author_ids: [], translator_ids: [], illustrator_ids: [])
  end
end
