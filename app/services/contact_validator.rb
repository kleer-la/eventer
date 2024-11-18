# frozen_string_literal: true

class ContactValidator
  attr_reader :error

  def initialize(params, secret = ENV['CONTACT_US_SECRET'], filter = Setting.get('CONTACT_US_MESSAGE_FILTER'))
    @params = params
    @error = nil
    @secret = secret.to_s
    @filter = filter
  end

  def valid?
    @error = validate
    @error.nil?
  end

  private

  def validate
    return 'bad secret' if invalid_secret?
    return 'bad name' if invalid_name?
    return 'bad message' if invalid_message?
    return 'empty email' if @params[:email].blank?
    return 'invalid email' if invalid_email?
    return 'empty context' if @params[:context].blank?

    'subject honeypot' if @params[:subject].present?
  end

  def invalid_secret?
    @secret.present? && @secret != @params[:secret]
  end

  def invalid_name?
    name = @params[:name].to_s.strip

    name.blank? ||
      name.length > 50 ||
      /[a-z]+[A-Z]+[a-z]/.match(name)
    # || /^[a-z]+[A-Z]/.match(name)
  end

  def invalid_message?
    message = @params[:message].to_s
    return true if message.blank?

    @filter&.split(',')&.any? { |f| message.include?(f) }
  end

  def invalid_email?
    @params[:email] !~ /\A[\w+\-.]+@[a-z\d-]+(\.[a-z]+)*\.[a-z]+\z/i
  end
end
