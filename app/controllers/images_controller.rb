require 'ostruct'

class ImagesController < ApplicationController
  def index
    store = FileStoreService.current
    @images = store.list
  end

  def new
    @image= OpenStruct.new
    @image.key = nil
end

  def create
    return "Falta información #{params[:image]} #{params[:path]}" if !params[:image].present? || !params[:path].present?
    @file = params[:image]
    @img_name = params[:path]

    store = FileStoreService.current

    file_path = store.upload(@file.tempfile, @img_name, 'kleer-images')
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
