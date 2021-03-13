class FileStoreService
  def self.createNull(exists: {})
    FileStoreService.new NullFileStore.new(exists: exists)
  end

  def self.createS3
    FileStoreService.new S3FileStore.new
  end

  def initialize store
    @store= store
  end

  def write filename
    key = File.basename(filename)
    @store.objects("certificates/#{key}").write(:file => filename )
    @store.objects("certificates/#{key}").acl = :public_read

    "https://s3.amazonaws.com/Keventer/certificates/#{key}"
  end

  def read(filename, suffix, folder='certificate-images')
    suffix = ('-' + suffix) if suffix.present?
    key = File.basename(filename,'.*') + suffix.to_s + File.extname(filename)

    if !@store.objects("#{folder}/#{key}").exists?
      raise ArgumentError,"#{key} image not found"
    end
    tmp_filename= tmp_path filename
    File.open(tmp_filename, 'wb') do |file|
      @store.objects("#{folder}/#{key}").read do |chunk|
        file.write(chunk)
      end
    end
    tmp_filename
  end

  def tmp_path basename
    temp_dir = "#{Rails.root}/tmp"
    Dir.mkdir( temp_dir ) unless Dir.exist?( temp_dir )
    temp_dir+'/'+basename
  end

end

class NullFileStore
  def initialize(exists:)
    @exists= exists
  end
  def objects key
    NullStoreObject.new(key, exists: @exists)
   end
end

class NullStoreObject
  attr_writer :key, :acl

  def initialize(key, exists:)
    @key= key
    @exists= exists
  end

  def read
    yield File.open("./spec/views/participants/base2021-A4.png").read
  end
  def write file:
  end
  def exists?
    @exists[@key].nil? ? true : @exists[@key]
  end
end

class S3FileStore
  def initialize(access_key_id: nil, secret_access_key: nil)
    s3 = AWS::S3.new(
      :access_key_id => access_key_id || ENV['KEVENTER_AWS_ACCESS_KEY_ID'],
      :secret_access_key => secret_access_key || ENV['KEVENTER_AWS_SECRET_ACCESS_KEY'])
    @bucket = s3.buckets['Keventer']
  end

  def objects key
    @bucket.objects[key]
  end
 end
 