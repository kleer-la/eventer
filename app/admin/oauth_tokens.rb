ActiveAdmin.register OauthToken do
  menu label: 'Tokens (Oauth)', priority: 1003

  filter :issuer
  filter :created_at

  actions :index, :show
end
