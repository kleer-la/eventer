ActiveAdmin.register OauthToken do
  menu label: 'Tokens (Oauth)', parent: 'Others', priority: 100

  filter :issuer
  filter :created_at

  actions :index, :show
end
