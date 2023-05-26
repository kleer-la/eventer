require 'ostruct'

class ImagesController < ApplicationController
  def index
    @image_bucket = params[:bucket] || session[:image_bucket] || 'image'
    session[:image_bucket] = @image_bucket

    store = FileStoreService.current
    @images = store.list(@image_bucket)
  end

  def new
    @image_bucket = session[:image_bucket]
    @image= OpenStruct.new
    @image.key = nil
  end

  def create
    return "Falta información #{params[:image]} #{params[:path]}" if !params[:image].present? || !params[:path].present?
    @image_bucket = params[:image_bucket]
    @file = params[:image]
    @img_name = params[:path]

    store = FileStoreService.current

    file_path = store.upload(@file.tempfile, @img_name, @image_bucket)
    render :show
  end

  def show
    @img_name = URI.decode_www_form_component(params[:i]) if params[:i].present?
  end

  def edit
  end

  def update
  end
end
