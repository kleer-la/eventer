# frozen_string_literal: true

ActiveAdmin.register_page 'Cache Reset' do
  menu parent: 'Assets', priority: 20, label: 'Website Cache Reset'

  content title: 'Website Cache Reset' do
    panel 'Reset Website Cache' do
      para 'This action will trigger a cache reset on the public website.'
      para 'The cache reset will be performed by making a GET request to the website with the configured token.'
      para 'Use this to force new content on the site (for instance, after changing a Page section). ' +
           'If not reseted, the cache will expire automatically after a 30 min of the last read.'

      active_admin_form_for :cache_reset, url: admin_cache_reset_execute_path do |f|
        f.actions do
          f.action :submit, label: 'Reset Cache',
                            button_html: { data: { confirm: 'Are you sure you want to reset the website cache?' } }
        end
      end
    end

    if flash[:notice] || flash[:error] || flash[:alert]
      panel 'Last Action Result' do
        if flash[:notice]
          div class: 'flash flash_notice' do
            flash[:notice]
          end
        end
        if flash[:error]
          div class: 'flash flash_error' do
            flash[:error]
          end
        end
        if flash[:alert]
          div class: 'flash flash_alert' do
            flash[:alert]
          end
        end
      end
    end
  end

  page_action :execute, method: :post do
    require 'net/http'
    require 'uri'

    token = ENV.fetch('CACHE_RESET_TOKEN', nil)

    if token.blank?
      flash[:error] = 'CACHE_RESET_TOKEN environment variable is not configured'
      redirect_to admin_cache_reset_path
      return
    end

    begin
      url = "https://www.kleer.la/cache-reset?token=#{token}"
      uri = URI.parse(url)

      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        flash[:notice] = "Cache reset successful. Response: #{response.code} #{response.message}"
      else
        flash[:alert] = "Cache reset request completed with status: #{response.code} #{response.message}"
      end
    rescue StandardError => e
      flash[:error] = "Error resetting cache: #{e.message}"
    end

    redirect_to admin_cache_reset_path
  end
end
