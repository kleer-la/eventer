# frozen_string_literal: true

require 'aws-sdk'

class FileStoreService
  def self.create_null(exists: {})
    FileStoreService.new NullFileStore.new(exists: exists)
  end

  def self.create_s3
    FileStoreService.new S3FileStore.new
  end

  def initialize(store)
    @store = store
  end

  def upload(tempfile, file_path, bucket= 'kleer-images')
    object = @store.objects(file_path, bucket)
    object.upload_file(tempfile)
    object.acl.put({ acl: 'public-read' })

    "https://s3.amazonaws.com/#{bucket}/#{file_path}"
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

    raise ArgumentError, "#{key} image not found" unless @store.objects("#{folder}/#{key}").exists?

    tmp_filename = tmp_path filename
    @store.objects("#{folder}/#{key}").download_file tmp_filename
    tmp_filename
  end

  def tmp_path(basename)
    temp_dir = "#{Rails.root}/tmp"
    Dir.mkdir(temp_dir) unless Dir.exist?(temp_dir)
    "#{temp_dir}/#{basename}"
  end

  def list(folder = 'certificate-images')
    @store.list_objects(bucket: 'kleer-images')
  end

end

class NullFileStore
  def initialize(exists:)
    @exists = exists
  end

  def objects(key, bucket_name= nil)
    NullStoreObject.new(key, exists: @exists)
  end
end

class NullStoreObject
  attr_writer :key, :acl

  def initialize(key, exists:)
    @key = key
    @exists = exists
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

  def objects(key, bucket_name= nil)
p key, bucket_name
    bucket = (@resource.bucket(bucket_name) if bucket_name.present?
            ) || @bucket
p bucket
    bucket.object(key)
  end

  def list_objects(bucket:)
    resp = @client.list_objects(bucket: bucket)
  end

end
