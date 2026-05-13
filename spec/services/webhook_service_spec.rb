require 'rails_helper'

RSpec.describe WebhookService do
  let(:webhook) { create(:webhook, url: 'https://example.com/webhook') }
  let(:contact) { create(:contact) }

  describe '#deliver' do
    it 'returns the response on 2xx so Delayed::Job marks the job done' do
      stub_request(:post, webhook.url).to_return(status: 200, body: 'ok')

      resp = described_class.new(contact, webhook: webhook).deliver

      expect(resp.status).to eq(200)
    end

    it 'raises on non-2xx so Delayed::Job retries the job' do
      stub_request(:post, webhook.url).to_return(status: 500, body: 'boom')

      expect do
        described_class.new(contact, webhook: webhook).deliver
      end.to raise_error(WebhookService::DeliveryError, /500/)
    end

    it 'raises on 4xx so Delayed::Job retries the job' do
      stub_request(:post, webhook.url).to_return(status: 422, body: 'bad')

      expect do
        described_class.new(contact, webhook: webhook).deliver
      end.to raise_error(WebhookService::DeliveryError, /422/)
    end

    it 'lets Faraday connection errors propagate so Delayed::Job retries the job' do
      stub_request(:post, webhook.url).to_raise(Faraday::ConnectionFailed.new('boom'))

      expect do
        described_class.new(contact, webhook: webhook).deliver
      end.to raise_error(Faraday::ConnectionFailed)
    end

    it 'is a no-op when no webhook is configured' do
      expect(described_class.new(contact, webhook: nil).deliver).to be_nil
    end
  end

  describe 'Delayed::Job integration' do
    it 'caps retries at 7 attempts via max_attempts on the payload' do
      stub_request(:post, webhook.url).to_return(status: 500)

      Delayed::Worker.delay_jobs = true
      begin
        described_class.new(contact, webhook: webhook).delay.deliver
      ensure
        Delayed::Worker.delay_jobs = false
      end

      job = Delayed::Job.last
      expect(job.max_attempts).to eq(7)
    end
  end
end
