require 'net/http'

module FileSizeChecker
  extend ActiveSupport::Concern
  require 'cgi'

  def get_remote_file_size(url)
    return 0 if url.blank?

    begin
      # Split the URL into base and path
      uri = URI(url.gsub(' ', '%20')) # Simple space replacement

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Be careful with this in production

      response = http.request_head(uri.path)
      size = response['content-length'].to_i
      Rails.logger.info "Size for #{url}: #{size} bytes"
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
