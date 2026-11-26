# frozen_string_literal: true

require 'jwt'

class OauthToken < ApplicationRecord
  serialize :token_set, coder: JSON

  def about_to_expire?
    token_expiry = Time.at(decoded_access_token['exp'])
    token_expiry < Time.current + 5.minutes
  end

  # The admin filters use none of its associations; ransack 6 needs that
  # said explicitly (#241).
  def self.ransackable_associations(_auth_object = nil) = []

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id id_value issuer tenant_id token_set updated_at]
  end

  private

  def decoded_access_token
    JWT.decode(token_set['access_token'], nil, false)[0]
  end
end
