require 'rails_helper'

RSpec.describe Webhook, type: :model do
  it 'validates presence of url and event' do
    webhook = Webhook.new
    expect(webhook).not_to be_valid
    expect(webhook.errors[:url]).to include('no puede estar en blanco') # Spanish locale
    expect(webhook.errors[:event]).to include('no puede estar en blanco')
  end

  it 'is valid with url and event' do
    webhook = Webhook.new(url: 'http://example.com', event: 'contact.created', active: true)
    expect(webhook).to be_valid
  end
end
