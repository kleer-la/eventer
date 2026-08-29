# frozen_string_literal: true

# Resolves the user behind an OAuth bearer token for the MCP server: a live,
# unrevoked token carrying the mcp scope maps to the User that authorized it.
module OauthAccess
  def self.valid?(plain_token)
    token = access_token(plain_token)
    token.present? && token.accessible? && token.includes_scope?('mcp') && token.resource_owner_id.present?
  end

  def self.authenticate(plain_token)
    return unless valid?(plain_token)

    User.find_by(id: access_token(plain_token).resource_owner_id)
  end

  def self.access_token(plain_token)
    return if plain_token.blank?

    Doorkeeper::AccessToken.by_token(plain_token)
  end
  private_class_method :access_token
end
