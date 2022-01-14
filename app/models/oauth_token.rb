# frozen_string_literal: true

require 'jwt'

class OauthToken < ApplicationRecord
  serialize :token_set, JSON

  def about_to_expire?
    token_expiry = Time.at(decoded_access_token['exp'])
    token_expiry < Time.current + 5.minutes
  end

  private

  def decoded_access_token
    JWT.decode(token_set['access_token'], nil, false)[0]
  end
end
