class WebHooksController < ActionController::API
  require 'base64'
  require 'openssl'
  require 'json'

  def index
    xero = XeroClientService::create_xero
    XeroWebHookJob.perform_later({'events' => [{
      'tenantId' => xero.tenant_id,
      'eventCategory' => 'INVOICE',
      'eventType' => 'UPDATE',
      'resourceId' => params[:invoice_id]
      }]
    })
    render html: "WebHooks controller respondiendo a GET con invoice_id: #{params[:invoice_id] || '<vacío>'}"
  end

  def post
    payload = request.body.read
    signature = request.env['HTTP_X_XERO_SIGNATURE']

    if validate(payload, signature)
      Log.log(:xero, :info, 'Procesando webhook', payload.to_s) if Setting.get(:LOG_LEVEL).to_i > 0 

      XeroWebHookJob.perform_later(JSON.parse(payload))
      head :ok
    else
      Log.log(:xero, :info, 'unauthorized hook', payload.to_s + ' signature' + signature.to_s )
      puts 'unauthorized hook' + payload.to_s
      head :unauthorized
    end
  end

  private

  def validate(payload, signature)
    key = ENV['XERO_WEBHOOK_KEY']
    if key.nil?
      Log.log(:xero, :error, 'Procesando webhook', 'XERO_WEBHOOK_KEY no definida')
      return false
    end

    calculated_signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, payload)).strip
    Log.log(:xero, :info, 'validate', "signature:#{signature} calculated_signature:#{calculated_signature}") if Setting.get(:LOG_LEVEL).to_i > 0 

    (signature == calculated_signature)
  end
end
