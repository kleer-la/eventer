# frozen_string_literal: true

require 'net/http'

# Which sections each overlay template of the website reads, as the website
# itself publishes it (website17's PageTemplates at /page-templates.json; its
# spec renders every template and fails when the list stops matching the
# views). Keventer uses it to warn whoever edits an overlay page about a
# section that would never show (kleer-la/eventer#243).
#
# Kept for an hour, and dropped whenever the website is told to refresh its
# cache (WebsiteCacheReset), which is also when a deploy of the site with a new
# template is noticed. Nil when the website is not configured or does not
# answer: callers say they could not check, instead of guessing.
class WebsitePageTemplates
  PATH = '/page-templates.json'
  TTL = 1.hour
  TIMEOUT = 3 # seconds: this is asked while an editor waits for a preview

  # { slug => { section_slug => what it shows } }, the home page under nil
  def self.fetch(website_url: ENV.fetch('WEBSITE_URL', nil))
    return if website_url.blank?

    Rails.cache.fetch(cache_key(website_url), expires_in: TTL, skip_nil: true) { load(website_url) }
  end

  def self.clear(website_url: ENV.fetch('WEBSITE_URL', nil))
    Rails.cache.delete(cache_key(website_url)) if website_url.present?
  end

  def self.url(website_url = ENV.fetch('WEBSITE_URL', nil)) = "#{website_url.to_s.chomp('/')}#{PATH}"

  def self.cache_key(website_url) = "website_page_templates/#{website_url}"

  def self.load(website_url)
    uri = URI.parse(url(website_url))
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                                   open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      http.get(uri.request_uri)
    end
    return unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch('templates').to_h { |t| [t['slug'], t['sections']] }
  rescue StandardError => e
    Rails.logger.warn("Page templates not read from #{uri}: #{e.message}")
    nil
  end
  private_class_method :load
end
