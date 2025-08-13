require 'rails_helper'

RSpec.describe Webhook, type: :model do
  let(:trainer) { create(:trainer) }

  it 'validates presence of url, event, and responsible' do
    webhook = Webhook.new
    expect(webhook).not_to be_valid
    expect(webhook.errors[:url]).to include('no puede estar en blanco') # Spanish locale
    expect(webhook.errors[:event]).to include('no puede estar en blanco')
    expect(webhook.errors[:responsible_id]).to include('no puede estar en blanco')
  end

  it 'is valid with url, event, and responsible trainer' do
    webhook = Webhook.new(url: 'http://example.com', event: 'contact.created', active: true, responsible: trainer)
    expect(webhook).to be_valid
  end

  it 'belongs to a responsible trainer' do
    webhook = create(:webhook)
    expect(webhook.responsible).to be_a(Trainer)
  end

  it 'can have a comment' do
    webhook = create(:webhook, comment: 'Test comment for webhook')
    expect(webhook.comment).to eq('Test comment for webhook')
  end
end
