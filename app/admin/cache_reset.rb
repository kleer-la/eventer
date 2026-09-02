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
    # force: a person clicked the button, so no throttle stands in their way.
    result = WebsiteCacheReset.new.call(force: true)

    case result.status
    when :ok then flash[:notice] = result.message
    when :not_configured then flash[:error] = result.message
    else flash[:alert] = result.message
    end

    redirect_to admin_cache_reset_path
  end
end
