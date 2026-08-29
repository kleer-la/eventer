# frozen_string_literal: true

# Base for every MCP tool. Resolves the user behind the OAuth token in the
# Authorization header so tools answer with the same permissions the admin
# screens would give that person.
class ApplicationTool < ActionTool::Base
  def current_user
    return @current_user if defined?(@current_user)

    @current_user = OauthAccess.authenticate(bearer_token)
  end

  def ability
    @ability ||= Ability.new(current_user)
  end

  private

  def bearer_token
    headers['authorization']&.delete_prefix('Bearer ')
  end
end
