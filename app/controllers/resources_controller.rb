# frozen_string_literal: true

class ResourcesController < ApplicationController
  before_action :set_resource, only: %i[show edit update destroy]

  # GET /resources
  def index
    @resources = Resource.order(created_at: :desc)
    respond_to do |format|
      format.html
      format.json do
        render json: @resources.order(created_at: :desc),
               methods: %i[category_name],
               include: { 
                  authors: { only: [:name, :gravatar_email, :landing, :twitter_username, :linkedin_url, :updated_at]},
                  translators: { only: [:name, :gravatar_email, :landing, :twitter_username, :linkedin_url] },
                 }
      end
    end
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
    params[:resource][:slug] = params[:resource][:slug].downcase if params[:resource][:slug].present?
    params.require(:resource)
          .permit(:format, :slug, :category_id,
                  :title_es, :description_es, :cover_es, :landing_es, :share_link_es, :share_text_es, :tags_es, :comments_es,
                  :title_en, :description_en, :cover_en, :landing_en, :share_link_en, :share_text_en, :tags_en, :comments_en,
                  author_ids: [], translator_ids: []
                )
  end
end
