# frozen_string_literal: true

# Who has a session-handoff account and token (#201). Read-only: the account is
# born from Google sign-in and the token is issued from the person's own page.
# The one thing operators can do is revoke a token.
ActiveAdmin.register HandoffUser do
  menu label: 'Handoff Users', parent: 'Others', priority: 103

  actions :index, :show
  config.sort_order = 'created_at_desc'

  filter :email
  filter :name
  filter :locale, as: :select, collection: HandoffUser::LOCALES
  filter :created_at

  member_action :revoke_token, method: :put do
    authorize! :revoke, resource
    resource.active_token&.revoke!
    redirect_to admin_handoff_user_path(resource), notice: 'Token revoked'
  end

  action_item :revoke_token, only: :show, if: -> { resource.active_token && authorized?(:revoke, resource) } do
    link_to 'Revoke token', revoke_token_admin_handoff_user_path(resource), method: :put,
                                                                            data: { confirm: 'Revoke this token?' }
  end

  index do
    id_column
    column :email
    column :name
    column :locale
    column('Token') { |user| status_tag(user.active_token ? 'Active' : 'None') }
    column('Last used') { |user| user.active_token&.last_used_at }
    column('Briefings this month', &:briefings_this_month)
    column :sign_in_count
    column :created_at
  end

  show do
    attributes_table do
      row :email
      row :name
      row :locale
      row :google_uid
      row :sign_in_count
      row :last_sign_in_at
      row :last_sign_in_ip
      row('Briefings this month', &:briefings_this_month)
      row :created_at
    end

    panel 'Tokens (only the digest is stored)' do
      table_for resource.handoff_tokens.order(created_at: :desc) do
        column :id
        column :created_at
        column :last_used_at
        column('State') { |token| status_tag(token.revoked? ? 'Revoked' : 'Active') }
        column :revoked_at
      end
    end
  end
end
