# frozen_string_literal: true

# Base for the session-handoff connector's tools (#202), served on /handoff/mcp
# to HandoffUsers. Their token never resolves to a User, so nothing the admin
# MCP can do is reachable from here, whatever id the HandoffUser has.
class HandoffTool < ApplicationTool
  authorize { current_handoff_user.present? }

  def current_handoff_user
    return @current_handoff_user if defined?(@current_handoff_user)

    @current_handoff_user = OauthAccess.handoff_user(bearer_token)
  end

  def current_user = nil
end
