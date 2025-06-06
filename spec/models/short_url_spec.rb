require 'rails_helper'

RSpec.describe ShortUrl, type: :model do
  let(:valid_attributes) do
    {
      original_url: 'https://example.com',
      short_code: 'my-link'
    }
  end

  describe 'validations' do
    subject { build(:short_url) }

    it 'validates original_url format' do
      short_url = build(:short_url, original_url: 'invalid-url')
      expect(short_url).not_to be_valid
      expect(short_url.errors[:original_url]).to include('no es válido')

      short_url.original_url = 'http://example.com'
      expect(short_url).to be_valid
    end

    it 'validates short_code format' do
      short_url = build(:short_url, short_code: 'inv@lid')
      expect(short_url).not_to be_valid
      expect(short_url.errors[:short_code]).to include('only allows letters, numbers, hyphens, and underscores')

      short_url.short_code = 'valid-link_123'
      expect(short_url).to be_valid
    end
  end

  describe 'database constraints' do
    it 'enforces not null on original_url' do
      expect { ShortUrl.create!(short_code: 'my-link', original_url: nil) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'enforces not null and default on click_count' do
      short_url = create(:short_url)
      expect(short_url.click_count).to eq(0)

      expect { ShortUrl.create!(short_code: 'my-link', original_url: 'https://example.com', click_count: nil) }
        .to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'enforces unique index on short_code' do
      create(:short_url, short_code: 'my-link')
      expect { ShortUrl.create!(original_url: 'https://example.com', short_code: 'my-link') }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'short_code generation' do
    it 'generates a 6-character alphanumeric short_code when none is provided' do
      short_url = create(:short_url, short_code: nil)
      expect(short_url.short_code).to match(/\A[a-zA-Z0-9]{6}\z/)
    end

    it 'uses user-suggested short_code when provided' do
      short_url = create(:short_url, short_code: 'custom-link')
      expect(short_url.short_code).to eq('custom-link')
    end

    it 'ensures generated short_code is unique' do
      existing = create(:short_url, short_code: 'abc123')
      allow(SecureRandom).to receive(:alphanumeric).and_return('abc123', 'xyz789')
      short_url = create(:short_url, short_code: nil)
      expect(short_url.short_code).to eq('xyz789')
    end
  end

  describe 'FriendlyId integration' do
    it 'finds a record by short_code' do
      short_url = create(:short_url, short_code: 'my-link')
      expect(ShortUrl.find('my-link')).to eq(short_url)
    end

    it 'raises RecordNotFound for invalid short_code' do
      expect { ShortUrl.find('invalid') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#click_count' do
    it 'defaults to 0 for new records' do
      short_url = create(:short_url)
      expect(short_url.click_count).to eq(0)
    end

    it 'can be incremented' do
      short_url = create(:short_url)
      short_url.increment!(:click_count)
      expect(short_url.click_count).to eq(1)
    end
  end
end