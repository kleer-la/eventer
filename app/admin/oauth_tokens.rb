ActiveAdmin.register OauthToken do
  menu label: 'Tokens (Oauth)', parent: 'Others', priority: 100

  filter :issuer
  filter :created_at

  actions :index, :show

  collection_action :new_oauth_token, method: :get do
    xero_client = XeroClientService.build_client
    redirect_to xero_client.authorization_url, allow_other_host: true
  end

  action_item :new_oauth_token, only: :index do
    link_to 'New Oauth Token', new_oauth_tokens_path
  end
end
