# frozen_string_literal: true

require 'net/http'
require 'resolv'
require 'ipaddr'

# Fetches an image from a public URL and stores it in the image bucket, so a
# picture that already lives somewhere on the web can be added without going
# through the admin upload form.
#
# Only public hosts over http/https are fetched, and only image content types:
# the caller decides the URL, so an unrestricted fetch would turn the server
# into a probe for whatever it can reach on its own network.
class ImageImportService
  MAX_BYTES = 15 * 1024 * 1024
  MAX_REDIRECTS = 3
  EXTENSIONS = { 'image/gif' => '.gif', 'image/png' => '.png', 'image/jpeg' => '.jpg',
                 'image/webp' => '.webp', 'image/svg+xml' => '.svg' }.freeze

  class FetchError < StandardError; end

  def initialize(url:, path: nil, overwrite: false)
    @url = url.to_s.strip
    @path = path
    @overwrite = overwrite
  end

  def call(confirm: false)
    body, content_type = fetch
    file_name = target_name(content_type)
    replacing = store.exists?(file_name)

    return { status: 'error', errors: ["#{file_name} already exists. Pass overwrite=true to replace it."] } if replacing && !@overwrite

    return preview(file_name, content_type, body.bytesize, replacing) unless confirm

    { status: 'saved', file_name: file_name, url: upload(body, file_name),
      bytes: body.bytesize, content_type: content_type, replaced: replacing }
  rescue FetchError => e
    { status: 'error', errors: [e.message] }
  end

  private

  def preview(file_name, content_type, bytes, replacing)
    warnings = []
    warnings << "#{file_name} already exists and would be replaced." if replacing
    warnings << 'Animated GIFs are stored as-is: no WebP conversion, so the file stays heavy.' if content_type == 'image/gif'
    { status: 'preview', file_name: file_name, content_type: content_type, bytes: bytes,
      url: FileStoreService.image_url(file_name, 'image'), warnings: warnings,
      note: 'Nothing was stored. Call again with confirm=true to upload it.' }
  end

  def upload(body, file_name)
    file = Tempfile.new(['import', File.extname(file_name)], binmode: true)
    file.write(body)
    file.flush
    store.upload(file, file_name, 'image')
  ensure
    file&.close
    file&.unlink
  end

  def store = FileStoreService.current

  def target_name(content_type)
    name = @path.presence || File.basename(URI.parse(@url).path.to_s)
    name = File.basename(name.to_s).gsub(/[^a-zA-Z0-9._ -]/, '-').delete_prefix('.')
    raise FetchError, 'Could not work out a file name; pass path explicitly' if name.blank?

    extension = EXTENSIONS[content_type]
    File.extname(name).downcase == extension ? name : "#{File.basename(name, '.*')}#{extension}"
  end

  def fetch(url = @url, redirects_left = MAX_REDIRECTS)
    uri = parse(url)
    response = request(uri)

    case response
    when Net::HTTPRedirection
      raise FetchError, 'Too many redirects' if redirects_left.zero?

      fetch(URI.join(url, response['location']).to_s, redirects_left - 1)
    when Net::HTTPSuccess
      body_of(response)
    else
      raise FetchError, "The URL answered #{response.code}"
    end
  rescue SocketError, Timeout::Error, SystemCallError, OpenSSL::SSL::SSLError => e
    raise FetchError, "Could not fetch the URL: #{e.message}"
  end

  def body_of(response)
    content_type = response['content-type'].to_s.split(';').first.to_s.strip.downcase
    raise FetchError, "#{content_type.presence || 'unknown'} is not an image type" unless EXTENSIONS.key?(content_type)

    body = response.body.to_s
    raise FetchError, "The image is #{body.bytesize} bytes, over the #{MAX_BYTES} limit" if body.bytesize > MAX_BYTES
    raise FetchError, 'The URL returned an empty body' if body.empty?

    [body, content_type]
  end

  def request(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                        open_timeout: 5, read_timeout: 15) do |http|
      http.request(Net::HTTP::Get.new(uri))
    end
  end

  def parse(url)
    uri = URI.parse(url)
    raise FetchError, 'Only http and https URLs are supported' unless %w[http https].include?(uri.scheme)
    raise FetchError, 'The URL has no host' if uri.host.blank?
    raise FetchError, "#{uri.host} is not a public host" unless public_host?(uri.host)

    uri
  rescue URI::InvalidURIError
    raise FetchError, "#{url.inspect} is not a valid URL"
  end

  # Blocks the server from being asked to fetch things only it can reach.
  def public_host?(host)
    addresses = Resolv.getaddresses(host)
    return false if addresses.empty?

    addresses.none? do |address|
      ip = IPAddr.new(address)
      ip.loopback? || ip.private? || ip.link_local?
    rescue IPAddr::Error
      true
    end
  end
end
