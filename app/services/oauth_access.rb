# frozen_string_literal: true

# Resolves the owner behind an OAuth bearer token for the MCP servers. A live,
# unrevoked token carries exactly one scope, and the scope says which model
# authorized it: `mcp` → a User (the admin MCP), `handoff` → a HandoffUser (the
# session-handoff connector). A token is only valid for the server whose scope
# it holds, and its owner is only ever looked up in that scope's model.
module OauthAccess
  OWNER_BY_SCOPE = { 'mcp' => 'User', 'handoff' => 'HandoffUser' }.freeze

  def self.valid?(plain_token, scope: 'mcp')
    token = access_token(plain_token)
    token.present? && token.accessible? && token.scopes.to_a == [scope] && owner_of(token, scope).present?
  end

  def self.authenticate(plain_token)
    owner(plain_token, 'mcp')
  end

  def self.handoff_user(plain_token)
    owner(plain_token, 'handoff')
  end

  def self.owner(plain_token, scope)
    return unless valid?(plain_token, scope: scope)

    owner_of(access_token(plain_token), scope)
  end

  # Tokens issued before owners were typed (resource_owner_type nil) are Users.
  def self.owner_of(token, scope)
    type = token.resource_owner_type || 'User'
    return unless type == OWNER_BY_SCOPE[scope]

    type.constantize.find_by(id: token.resource_owner_id)
  end

  def self.access_token(plain_token)
    return if plain_token.blank?

    Doorkeeper::AccessToken.by_token(plain_token)
  end
  private_class_method :access_token, :owner, :owner_of
end
