require 'faraday'

class WebhookService
  def initialize(contact, webhook: nil)
    @contact = contact
    @webhook = webhook || Webhook.find_by(event: "contact.#{@contact.trigger_type}", active: true)
  end

  def deliver
    return unless @webhook

    conn = Faraday.new(url: @webhook.url)
    resp = conn.post do |req|
      req.body = {
        contact: {
          id: @contact.id,
          name: @contact.name,
          email: @contact.email,
          company: @contact.company,
          resource_slug: @contact.resource_slug,
          trigger_type: @contact.trigger_type,
          content_updates_opt_in: @contact.content_updates_opt_in,
          newsletter_opt_in: @contact.newsletter_opt_in,
          language: @contact.form_data['language'] || 'es'
        }
      }.to_json
      req.headers['Content-Type'] = 'application/json'
    end
    Log.log(:mail, :info, 'Webhook', "#{resp.status} - #{resp.body}")
    resp
  end
end
