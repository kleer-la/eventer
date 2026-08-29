# frozen_string_literal: true

# OAuth connections held by MCP clients (Claude Desktop / claude.ai / Claude
# Code). Everyone sees and revokes their own; administrators see them all.
# Revoking is the way to cut a client off without touching the console.
ActiveAdmin.register Doorkeeper::AccessToken, as: 'MCP Connection' do
  menu label: 'MCP Connections', parent: 'Others'
  actions :index

  config.sort_order = 'created_at_desc'

  Doorkeeper::AccessToken.class_eval do
    def self.ransackable_attributes(_auth_object = nil)
      %w[application_id created_at expires_in id resource_owner_id revoked_at scopes]
    end

    def self.ransackable_associations(_auth_object = nil)
      %w[application]
    end
  end

  Doorkeeper::Application.class_eval do
    def self.ransackable_attributes(_auth_object = nil)
      %w[created_at id name scopes]
    end
  end

  filter :application, as: :select, collection: -> { Doorkeeper::Application.order(:name) }

  controller do
    def scoped_collection
      scope = Doorkeeper::AccessToken.includes(:application)
      current_user.role?(:administrator) ? scope : scope.where(resource_owner_id: current_user.id)
    end
  end

  index download_links: false do
    column('Client') { |token| token.application&.name }
    column('User') { |token| User.find_by(id: token.resource_owner_id)&.email }
    column('Created', &:created_at)
    column('Expires', &:expires_at)
    column('Status') do |token|
      if token.accessible?
        status_tag('Active', class: 'ok')
      else
        status_tag(token.revoked? ? 'Revoked' : 'Expired', class: 'error')
      end
    end
    column('') do |token|
      if token.accessible?
        confirmation = 'Revoke this connection? The client stops working immediately.'
        link_to 'Revoke', revoke_admin_mcp_connection_path(token),
                method: :put, data: { confirm: confirmation }
      end
    end
  end

  # PUT, not GET: it has an effect, and a GET would be reachable by CSRF.
  # Revokes every token the client holds for this user, not just this row —
  # otherwise a live refresh token would let it mint a new one straight away.
  member_action :revoke, method: :put do
    token = Doorkeeper::AccessToken.find(params[:id])
    authorize! :revoke, token

    Doorkeeper::AccessToken.where(application_id: token.application_id,
                                  resource_owner_id: token.resource_owner_id).find_each(&:revoke)
    redirect_to collection_path, notice: 'Connection revoked.'
  end
end
