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

  CONVERTIBLE = %w[image/png image/jpeg].freeze

  def initialize(url:, path: nil, overwrite: false, convert_to_webp: true)
    @url = url.to_s.strip
    @path = path
    @overwrite = overwrite
    @convert_to_webp = convert_to_webp
  end

  def call(confirm: false)
    body, content_type = fetch
    file_name = target_name(content_type)
    replacing = store.exists?(file_name)

    if replacing && !@overwrite
      return { status: 'error',
               errors: ["#{file_name} already exists. Pass overwrite=true to replace it."] }
    end

    return preview(file_name, content_type, body.bytesize, replacing) unless confirm

    { status: 'saved', file_name: file_name, url: upload(body, file_name),
      bytes: body.bytesize, content_type: content_type, replaced: replacing }
      .merge(webp_twin(body, file_name, content_type))
  rescue FetchError => e
    { status: 'error', errors: [e.message] }
  rescue Aws::Errors::ServiceError => e
    # Reaching the image store failed. Say which call broke rather than letting
    # a bare AWS error escape as a tool crash.
    { status: 'error', errors: ["The image store rejected the request (#{e.class.name.demodulize})"] }
  end

  private

  def preview(file_name, content_type, bytes, replacing)
    warnings = []
    warnings << "#{file_name} already exists and would be replaced." if replacing
    if content_type == 'image/gif'
      warnings << 'Animated GIFs are stored as-is: no WebP conversion, so the file stays heavy.'
    end
    { status: 'preview', file_name: file_name, content_type: content_type, bytes: bytes,
      url: FileStoreService.image_url(file_name, 'image'), warnings: warnings,
      also_stores: (webp_name(file_name) if converts?(content_type)),
      note: 'Nothing was stored. Call again with confirm=true to upload it.' }.compact
  end

  def converts?(content_type)
    @convert_to_webp && CONVERTIBLE.include?(content_type)
  end

  def webp_name(file_name)
    File.join([File.dirname(file_name), ImageConversionService.webp_filename(file_name)].reject { |p| p == '.' })
  end

  # A PNG or JPEG gets a WebP twin next to it, as the admin upload does. A
  # failed conversion is reported, never hidden: the original is stored anyway.
  def webp_twin(body, file_name, content_type)
    return {} unless converts?(content_type)

    twin = webp_name(file_name)
    { webp_file_name: twin, webp_url: upload(converted(body, File.extname(file_name)), twin) }
  rescue StandardError => e
    { warnings: ["#{file_name} was stored, but its WebP twin was not: #{e.message}"] }
  end

  def converted(body, extension)
    source = Tempfile.new(['import', extension], binmode: true)
    source.write(body)
    source.flush
    webp_path = ImageConversionService.convert_to_webp(source.path)
    File.binread(webp_path)
  ensure
    source&.close!
    FileUtils.rm_f(webp_path.to_s) if webp_path
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
    body = response.body.to_s
    raise FetchError, 'The URL returned an empty body' if body.empty?
    raise FetchError, "The image is #{body.bytesize} bytes, over the #{MAX_BYTES} limit" if body.bytesize > MAX_BYTES

    # The file itself decides, not the header: images served straight from a
    # bucket usually arrive as application/octet-stream, and a server is free
    # to claim image/png for a login page.
    content_type = detect_type(body)
    if content_type.nil?
      declared = response['content-type'].to_s.split(';').first.to_s.strip.presence || 'nothing'
      raise FetchError, "That does not look like an image (the server declared #{declared})"
    end

    [body, content_type]
  end

  def detect_type(body)
    head = body.byteslice(0, 16).to_s.b
    return 'image/gif' if head.start_with?('GIF87a'.b, 'GIF89a'.b)
    return 'image/png' if head.start_with?("\x89PNG\r\n\x1A\n".b)
    return 'image/jpeg' if head.start_with?("\xFF\xD8\xFF".b)
    return 'image/webp' if head.byteslice(0, 4) == 'RIFF'.b && head.byteslice(8, 4) == 'WEBP'.b
    return 'image/svg+xml' if svg?(body)

    nil
  end

  def svg?(body)
    body.byteslice(0, 2000).to_s.force_encoding(Encoding::UTF_8).valid_encoding? &&
      body.byteslice(0, 2000).to_s.include?('<svg')
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
