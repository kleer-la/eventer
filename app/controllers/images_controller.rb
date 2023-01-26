require 'ostruct'

class ImagesController < ApplicationController
  def index
    store = FileStoreService.create_s3
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

    store = FileStoreService.create_s3
    @uri = store.upload(@file.tempfile, file_path, 'kleer-images')
    # s3.put_object(
    #   body: file.tempfile,
    #   bucket: 'YOUR_BUCKET_NAME',
    #   key: file.original_filename
    # )
  end

  def show
  end

  def edit
  end

  def update
  end
end
