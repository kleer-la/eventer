# frozen_string_literal: true

ActiveAdmin.register OauthToken do
  menu label: 'Tokens (Oauth)', parent: 'Others', priority: 100

  filter :issuer
  filter :created_at

  actions :index, :show

  # Define the collection action for new token generation
  collection_action :new_oauth_token, method: :get do
    xero_client = XeroClientService.build_client
    redirect_to xero_client.authorization_url, allow_other_host: true
  end

  # Define the callback action
  collection_action :callback, method: :get do
    xero_client = XeroClientService.build_client
    token_set = xero_client.get_token_set_from_callback(params)

    if token_set['error']
      redirect_to admin_oauth_tokens_path, notice: "Error generating token. #{token_set['error']}"
    else
      xero_client.set_token_set(token_set)

      oauth_token = OauthToken.first_or_create
      oauth_token.issuer = 'Xero'
      oauth_token.token_set = token_set
      oauth_token.tenant_id = xero_client.connections.last['tenantId']
      oauth_token.save!

      redirect_to admin_oauth_tokens_path, notice: 'Token generated successfully!'
    end
  end

  # Add the action item button
  action_item :new_oauth_token, only: :index do
    link_to 'New Oauth Token', new_oauth_token_admin_oauth_tokens_path
  end

  # Customize the index page
  index do
    column :issuer
    column :tenant_id
    column :created_at
    column :updated_at
    actions
  end

  # Customize the show page
  show do
    attributes_table do
      row :issuer
      row :tenant_id
      row :created_at
      row :updated_at
      row :token_set
    end
  end
end
