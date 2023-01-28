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
    file_path = params[:path]

    store = FileStoreService.current
    @uri = store.upload(@file.tempfile, file_path, 'kleer-images')
  end

  def show
    @img_name = URI.decode_www_form_component(params[:i]) if params[:i].present?
  end

  def edit
  end

  def update
  end
end
