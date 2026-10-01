# frozen_string_literal: true

# Where a file that only exists on a client's machine is PUT before it is
# imported like any image at a URL (kleer-la/eventer#216): a key of its own
# under incoming/, a presigned URL to write it and one to read it back. The
# image list leaves incoming/ out, and the import drops the copy once stored.
module IncomingUploads
  INCOMING = 'incoming/'
  INCOMING_HOST = 'kleer-images.s3.sa-east-1.amazonaws.com'
  SLOT_MINUTES = 15

  def upload_slot(file_name)
    key = "#{INCOMING}#{SecureRandom.uuid}/#{File.basename(file_name)}"
    bucket, = self.class.image_location('image')
    { key:, put_url: @store.presigned_url(key, bucket, :put, SLOT_MINUTES.minutes.to_i),
      get_url: @store.presigned_url(key, bucket, :get, 1.hour.to_i) }
  end

  # The key of a staging copy, given the URL it was read from; nil otherwise.
  def incoming_key(url)
    uri = URI.parse(url.to_s)
    key = URI::DEFAULT_PARSER.unescape(uri.path.to_s.delete_prefix('/'))
    key if uri.host == INCOMING_HOST && key.start_with?(INCOMING)
  rescue URI::InvalidURIError
    nil
  end
end
