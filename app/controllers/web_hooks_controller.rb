class WebHooksController < ActionController::API
  require 'base64'
  require 'openssl'
  require 'json'

  def index
    render html: 'WebHooks controller respondiendo a GET'
  end

  def post
    payload = request.body.read
    signature = request.env['HTTP_X_XERO_SIGNATURE']

    if validate(payload, signature)
      # XeroWebHookJob.perform_later(JSON.parse(payload))
      puts 'ok hook' + payload.to_s
      head :ok
    else
      puts 'unauthrized hook' + payload.to_s
      head :unauthorized
    end
  end

  private

  def validate(payload, signature)
    key = ENV['XERO_WEBHOOK_KEY']
    calculated_signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, payload)).strip

    (signature == calculated_signature)
  end
end
