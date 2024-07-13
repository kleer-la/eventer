# frozen_string_literal: true

require 'aws-sdk-s3'
require 'ostruct'

class FileStoreService
  @current = nil

  def self.create_null(exists: {})
    @current = FileStoreService.new NullFileStore.new(exists:)
  end

  def self.create_s3
    @current = FileStoreService.new S3FileStore.new
  end

  def self.current
    create_s3 if @current.nil?
    @current
  end

  def self.image_location(image_type)
    bucket = 'Keventer'
    bucket = 'kleer-images' if image_type == 'image'
    folder = {
      'image' => nil,
      'certificate' => 'certificate-images/',
      'signature' => 'certificate-signatures/'
    }[image_type]
    [bucket, folder]
  end

  def self.image_url(image_name, image_type)
    return "https://kleer-images.s3.sa-east-1.amazonaws.com/#{image_name&.gsub(' ', '+')}" if image_type == 'image'

    bucket = 'Keventer'
    folder = {
      'certificate' => 'certificate-images/',
      'signature' => 'certificate-signatures/'
    }[image_type]
    file_name = image_name&.gsub(' ', '+')&.gsub(folder.to_s, '')
    "https://s3.amazonaws.com/#{bucket}/#{folder}#{file_name}"
  end

  def initialize(store)
    @store = store
  end

  def upload(tempfile, file_name, image_bucket = 'image')
    bucket, folder = self.class.image_location(image_bucket)

    file_path = folder.to_s + file_name
    object = @store.objects(file_path, bucket)
    object.upload_file(tempfile)
    object.acl.put({ acl: 'public-read' })

    # "https://s3.amazonaws.com/#{bucket}/#{file_path}"
    self.class.image_url(file_name, image_bucket)
  end

  def write(filename)
    key = File.basename(filename)
    object = @store.objects("certificates/#{key}")
    object.upload_file(filename)
    object.acl.put({ acl: 'public-read' })

    "https://s3.amazonaws.com/Keventer/certificates/#{key}"
  end

  def read(filename, suffix, folder = 'certificate-images')
    raise ArgumentError, 'image filename blank' if filename.blank?

    suffix = "-#{suffix}" if suffix.present?
    key = File.basename(filename, '.*') + suffix.to_s + File.extname(filename)

    unless @store.objects("#{folder}/#{key}").exists?
      Log.log(:aws, :error,
              'get file - Image not found',
              "filename:#{filename} suffix:#{suffix} folder: #{folder} - \\n#{caller.grep_v(%r{/gems/}).join('\n')}")
      raise ArgumentError, "#{folder}/#{key} image not found"
    end

    tmp_filename = tmp_path filename
    @store.objects("#{folder}/#{key}").download_file tmp_filename
    tmp_filename
  end

  def tmp_path(basename)
    temp_dir = "#{Rails.root}/tmp"
    Dir.mkdir(temp_dir) unless Dir.exist?(temp_dir)
    "#{temp_dir}/#{basename}"
  end

  def list(image_type = 'image')
    bucket, folder = self.class.image_location(image_type)
    result = @store.list_objects(bucket:).contents
    result = result.select { |img| img.key.to_s.start_with? folder } unless folder.nil?
    result
  end
end

class NullFileStore
  def initialize(exists:)
    @exists = exists
  end

  def objects(key, _bucket_name = nil)
    NullStoreObject.new(key, exists: @exists)
  end

  def list_objects(bucket:)
    list = OpenStruct.new
    list.contents = [NullStoreObject.new('some file.png', exists: @exists)]
    list
  end
end

class NullStoreObject
  attr_writer :acl
  attr_accessor :key, :last_modified, :size

  def initialize(key, exists:)
    @key = key
    @exists = exists
    @last_modified = Date.yesterday
    @size = 12_345
  end

  def download_file(file)
    FileUtils.cp './spec/views/participants/base2021-A4.png', file
  end

  def upload_file(file); end

  def exists?
    @exists[@key].nil? ? true : @exists[@key]
  end

  def acl
    NullStoreObjectAcl.new
  end
end

class NullStoreObjectAcl
  def put(hash); end
end

class S3FileStore
  def initialize(access_key_id: nil, secret_access_key: nil)
    @client = Aws::S3::Client.new(
      access_key_id: access_key_id || ENV['KEVENTER_AWS_ACCESS_KEY_ID'],
      secret_access_key: secret_access_key || ENV['KEVENTER_AWS_SECRET_ACCESS_KEY']
    )
    @resource = Aws::S3::Resource.new(client: @client)
    @bucket = @resource.bucket('Keventer')
  end

  def objects(key, bucket_name = nil)
    bucket = @resource.bucket(bucket_name) if bucket_name.present?
    (bucket || @bucket).object(key)
  end

  def list_objects(bucket:)
    @client.list_objects(bucket:)
  end
end
