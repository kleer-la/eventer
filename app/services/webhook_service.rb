require 'faraday'

class WebhookService
  def initialize(contact)
    @contact = contact
  end

  def deliver
    webhook = Webhook.find_by(event: 'contact.created', active: true)
    return unless webhook

    conn = Faraday.new(url: webhook.url)
    conn.post do |req|
      req.body = {
        contact: {
          id: @contact.id,
          name: @contact.name,
          email: @contact.email,
          company: @contact.company,
          resource_slug: @contact.resource_slug,
          trigger_type: @contact.trigger_type
        }
      }.to_json
      req.headers['Content-Type'] = 'application/json'
    end
  end
end
