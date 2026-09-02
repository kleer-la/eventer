# frozen_string_literal: true

class RefreshWebsiteCacheTool < AuthenticatedTool
  tool_name 'refresh_website_cache'
  requires_permission :read, Article

  description <<~TEXT
    Makes the public website reload the content it caches from here, so a change
    saved through these tools shows up right away.

    The website picks changes up on its own within 30 minutes, so only use this
    when someone is waiting to see something now — and once you have finished
    editing, not after each change. Calling it again within a minute is skipped
    rather than repeated.
  TEXT

  arguments do
  end

  def call
    result = WebsiteCacheReset.new.call

    case result.status
    when :ok then { status: 'ok', message: result.message }
    when :throttled then { status: 'skipped', message: result.message }
    else { status: 'error', errors: [result.message] }
    end.to_json
  end
end
