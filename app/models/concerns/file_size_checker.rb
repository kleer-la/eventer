require 'net/http'

module FileSizeChecker
  extend ActiveSupport::Concern
  require 'cgi'

  BASE_URL = 'https://www.kleer.la'

  def get_remote_file_size(url)
    return 0 if url.blank?

    full_url = url.start_with?('http://', 'https://') ? url : "#{BASE_URL}#{url}"

    begin
      uri = URI(full_url.gsub(' ', '%20'))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

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
