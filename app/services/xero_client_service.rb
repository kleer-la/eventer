module XeroClientService
  def self.build_client
    creds = {
      client_id: XERO_CLIENT_ID,
      client_secret: XERO_CLIENT_SECRET,
      redirect_uri: XERO_REDIRECT_URI,
      scopes: XERO_SCOPES
    }
    config = {
      # timeout: 30,
      # debugging: Rails.env.development?
    }
    xero_client ||= XeroRuby::ApiClient.new(credentials: creds, config: config)
  end

  def self.initialized_client
    oauth_token = OauthToken.first

    xero_client = build_client
    xero_client.set_token_set(oauth_token.token_set)

    if oauth_token.about_to_expire?
      puts 'Refrescando token'
      # este método almacena en el cliente el nuevo token
      new_token_set = xero_client.refresh_token_set(oauth_token.token_set)
      unless new_token_set['error']
        oauth_token.token_set = new_token_set
        # Por el momento desactivo esta actualización para prevenir un problema
        # detectado (y aparentemente resuelto) en xero-ruby en versiones previas
        # a la 2.9.1
        # oauth_token.tenant_id = xero_client.connections.last['tenantId']
        oauth_token.save!
        puts 'Token refrescado'
      end
    end

    [xero_client, oauth_token.tenant_id]
  end

  raise 'You must specify the XERO_CLIENT_ID env variable' unless XERO_CLIENT_ID = ENV['XERO_CLIENT_ID']

  raise 'You must specify the XERO_CLIENT_SECRET env variable' unless XERO_CLIENT_SECRET = ENV['XERO_CLIENT_SECRET']

  raise 'You must specify the XERO_REDIRECT_URI env variable' unless XERO_REDIRECT_URI = ENV['XERO_REDIRECT_URI']

  raise 'You must specify the XERO_SCOPES env variable' unless XERO_SCOPES = ENV['XERO_SCOPES']
end
