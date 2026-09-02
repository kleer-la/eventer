# frozen_string_literal: true

require 'net/http'

# Tells the public website to drop the content it caches from this API.
#
# The site refreshes on its own within 30 minutes; this is for when somebody is
# waiting to see a change now. Two callers share it: the admin screen, where a
# person clicked the button and means it, and the MCP tool, where an assistant
# may ask after every single edit — hence the throttle, which keeps a burst of
# edits from turning the website's cache off.
class WebsiteCacheReset
  THROTTLE = 60.seconds
  DEFAULT_STAMP_PATH = Rails.root.join('tmp/website_cache_reset_at')

  Result = Struct.new(:status, :message, keyword_init: true) do
    def ok? = status == :ok
  end

  def initialize(website_url: ENV.fetch('WEBSITE_URL', nil), token: ENV.fetch('CACHE_RESET_TOKEN', nil),
                 stamp_path: DEFAULT_STAMP_PATH)
    @website_url = website_url
    @token = token
    @stamp_path = stamp_path
  end

  def call(force: false)
    return not_configured if @website_url.blank? || @token.blank?

    ago = seconds_since_last_reset
    return throttled(ago) if !force && ago && ago < THROTTLE

    refresh
  end

  private

  def refresh
    response = Net::HTTP.get_response(URI.parse("#{@website_url}/cache-reset?token=#{@token}"))
    return failed("#{@website_url} answered #{response.code} #{response.message}") unless
      response.is_a?(Net::HTTPSuccess)

    stamp_reset
    Result.new(status: :ok, message: "#{@website_url} reloaded the content it had cached")
  rescue StandardError => e
    # The site being unreachable is not the caller's fault, and not worth an
    # exception: the cache expires by itself anyway.
    failed("#{@website_url} could not be reached: #{e.message}")
  end

  def not_configured
    Result.new(status: :not_configured,
               message: 'WEBSITE_URL or CACHE_RESET_TOKEN is not configured, so the website cannot be told')
  end

  def throttled(ago)
    Result.new(status: :throttled,
               message: "#{@website_url} was already refreshed #{ago.round} seconds ago; " \
                        'it is showing the current content. Refresh once you are done editing, not after ' \
                        'each change.')
  end

  # Never carries the token: this text ends up in a flash message and in an
  # assistant's answer.
  def failed(message) = Result.new(status: :failed, message: message)

  def seconds_since_last_reset
    Time.current - File.mtime(@stamp_path)
  rescue SystemCallError
    nil # nothing has been refreshed since this container started
  end

  def stamp_reset
    FileUtils.mkdir_p(File.dirname(@stamp_path))
    FileUtils.touch(@stamp_path)
  rescue SystemCallError => e
    Rails.logger.warn("Website cache reset not recorded, so the throttle is off: #{e.message}")
  end
end
