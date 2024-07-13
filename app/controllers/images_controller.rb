require 'ostruct'

class ImagesController < ApplicationController
  def index
    @image_bucket = params[:bucket] || session[:image_bucket] || 'image'
    session[:image_bucket] = @image_bucket

    begin
      store = FileStoreService.current
      @images = store.list(@image_bucket)
    rescue Aws::Errors::MissingCredentialsError
      flash.now[:error] = 'AWS credentials are missing. Please check your configuration.'
      @images = []
    end
  end

  def new
    @image_bucket = session[:image_bucket]

    @image = OpenStruct.new
    @image.key = nil
  end

  def create
    return "Falta información #{params[:image]} #{params[:path]}" if !params[:image].present? || !params[:path].present?

    session[:image_bucket] = @image_bucket = params[:image_bucket]

    @file = params[:image]
    @img_name = params[:path]

    store = FileStoreService.current

    @public_url = store.upload(@file.tempfile, @img_name, @image_bucket)

    render :show
  end

  def show
    @image_bucket = params[:bucket] || session[:image_bucket] || 'image'

    @public_url = FileStoreService.image_url(params[:i], @image_bucket)
  end

  def edit; end

  def update; end
end
