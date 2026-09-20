# frozen_string_literal: true

require 'rails_helper'

describe HandoffUser do
  def auth(email: 'ana@example.com', uid: 'g-1', verified: true, name: 'Ana')
    OmniAuth::AuthHash.new(provider: 'google_oauth2', uid: uid,
                           info: { email: email, name: name },
                           extra: { raw_info: { email_verified: verified } })
  end

  def request_resource(email: 'ana@example.com', language: 'es')
    Contact.create!(trigger_type: :download_form, email: email,
                    form_data: { 'resource_slug' => 'session-handoff', 'language' => language, 'name' => 'Ana' })
  end

  describe '.from_google' do
    it 'creates the user from a verified Google identity that requested the resource' do
      request_resource

      user = described_class.from_google(auth)

      expect(user).to be_persisted
      expect(user).to have_attributes(email: 'ana@example.com', name: 'Ana', google_uid: 'g-1', locale: 'es')
    end

    it 'takes the language of the request' do
      request_resource(language: 'en')

      expect(described_class.from_google(auth).locale).to eq 'en'
    end

    it 'matches the request email regardless of case' do
      request_resource(email: 'Ana@Example.com')

      expect(described_class.from_google(auth)).to be_persisted
    end

    it 'refuses an identity that never requested the resource' do
      Contact.create!(trigger_type: :download_form, email: 'ana@example.com',
                      form_data: { 'resource_slug' => 'otro-recurso', 'language' => 'es' })

      expect(described_class.from_google(auth)).to be_nil
      expect(described_class.count).to eq 0
    end

    it 'keeps letting an existing user in, request or not' do
      request_resource
      described_class.from_google(auth)
      Contact.delete_all

      expect(described_class.from_google(auth)).to be_persisted
    end

    it 'finds the same user by uid and refreshes email and name' do
      request_resource
      described_class.from_google(auth)

      user = described_class.from_google(auth(email: 'ana.new@example.com', name: 'Ana B'))

      expect(described_class.count).to eq 1
      expect(user).to have_attributes(email: 'ana.new@example.com', name: 'Ana B')
    end

    it 'refuses an unverified email' do
      request_resource

      expect(described_class.from_google(auth(verified: false))).to be_nil
      expect(described_class.count).to eq 0
    end
  end

  describe '.requested?' do
    it 'is true only for a download request of this resource with that email' do
      request_resource(email: 'ana@example.com')

      expect(described_class.requested?('ANA@example.com')).to be true
      expect(described_class.requested?('nadie@example.com')).to be false
    end
  end

  describe '#briefings_this_month' do
    it 'counts only this month and only this user' do
      user = create(:handoff_user)
      other = create(:handoff_user, email: 'b@example.com', google_uid: 'g-2')
      TtsUsage.create!(status: 'ok', beats_count: 1, chars: 1, owner_id: user.id)
      TtsUsage.create!(status: 'error', beats_count: 1, chars: 1, owner_id: user.id)
      TtsUsage.create!(status: 'ok', beats_count: 1, chars: 1, owner_id: user.id, created_at: 2.months.ago)
      TtsUsage.create!(status: 'ok', beats_count: 1, chars: 1, owner_id: other.id)

      expect(user.briefings_this_month).to eq 2
    end
  end
end
