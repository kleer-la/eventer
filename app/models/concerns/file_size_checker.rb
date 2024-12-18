require 'net/http'

module FileSizeChecker
  extend ActiveSupport::Concern
  require 'addressable/uri'

  BASE_URL = 'https://www.kleer.la'

  def get_remote_file_size(url)
    return 0 if url.blank?

    clear_url = url.strip
    full_url = clear_url.start_with?('http://', 'https://') ? clear_url : "#{BASE_URL}#{clear_url}"

    begin
      uri = Addressable::URI.parse(full_url).normalize
      port = uri.scheme == 'https' ? 443 : 80
      http = Net::HTTP.new(uri.host, port)

      http.use_ssl = (uri.scheme == 'https')
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.max_retries = 3 # Add retries
      end

      # Add these lines to match wget's behavior better
      http.keep_alive_timeout = 30
      http.max_retries = 3
      http.read_timeout = 30
      http.open_timeout = 30
      # Create request with full path and headers
      request = Net::HTTP::Head.new(uri.request_uri)
      request['User-Agent'] = "Ruby/#{RUBY_VERSION}"
      request['Accept'] = '*/*'
      request['Accept-Encoding'] = 'identity' # Request uncompressed content

      response = http.request(request)

      size = response['content-length'].to_i
      Rails.logger.info "Size for #{full_url}: #{size} bytes"
      size
    rescue StandardError => e
      Rails.logger.error "Error checking file size for #{url}: #{e.message}"
      0
    end
  end

  def cover_size(locale = :es)
    cover_url = send("cover_#{locale}")
    get_remote_file_size(cover_url)
  end
end
