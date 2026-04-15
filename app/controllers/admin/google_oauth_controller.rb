# frozen_string_literal: true

module Admin
  class GoogleOauthController < ApplicationController
    before_action :authenticate_user!

    def authorize
      trainer = Trainer.find(params[:trainer_id])

      client = build_oauth_client
      client.state = trainer.id.to_s
      client.additional_parameters = { access_type: 'offline', prompt: 'consent' }

      redirect_to client.authorization_uri.to_s, allow_other_host: true
    end

    def callback
      client = build_oauth_client
      client.code = params[:code]
      token_response = client.fetch_access_token!

      trainer = Trainer.find(params[:state])
      trainer.update!(
        google_uid: fetch_google_uid(token_response['access_token']),
        google_access_token: token_response['access_token'],
        google_refresh_token: token_response['refresh_token'],
        google_token_expires_at: Time.current + token_response['expires_in'].to_i.seconds,
        google_calendar_connected: true
      )

      redirect_to admin_trainer_path(trainer), notice: 'Google Calendar connected successfully'
    rescue StandardError => e
      Rails.logger.error "Google OAuth error: #{e.message}"
      redirect_to admin_trainers_path, alert: "OAuth failed: #{e.message}"
    end

    private

    def build_oauth_client
      Signet::OAuth2::Client.new(
        client_id: ENV.fetch('GOOGLE_CLIENT_ID', ''),
        client_secret: ENV.fetch('GOOGLE_CLIENT_SECRET', ''),
        authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
        token_credential_uri: 'https://oauth2.googleapis.com/token',
        redirect_uri: admin_google_oauth_callback_url,
        scope: GoogleCalendarService::SCOPES.join(' ')
      )
    end

    def fetch_google_uid(access_token)
      uri = URI('https://www.googleapis.com/oauth2/v1/userinfo')
      uri.query = URI.encode_www_form(access_token: access_token)
      response = Net::HTTP.get_response(uri)
      JSON.parse(response.body)['id']
    rescue StandardError
      nil
    end
  end
end
