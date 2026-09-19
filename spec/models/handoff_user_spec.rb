# frozen_string_literal: true

require 'rails_helper'

describe HandoffUser do
  def auth(email: 'ana@example.com', uid: 'g-1', verified: true, name: 'Ana')
    OmniAuth::AuthHash.new(provider: 'google_oauth2', uid: uid,
                           info: { email: email, name: name },
                           extra: { raw_info: { email_verified: verified } })
  end

  describe '.from_google' do
    it 'creates the user from a verified Google identity' do
      user = described_class.from_google(auth)

      expect(user).to be_persisted
      expect(user).to have_attributes(email: 'ana@example.com', name: 'Ana', google_uid: 'g-1')
    end

    it 'finds the same user by uid and refreshes email and name' do
      described_class.from_google(auth)

      user = described_class.from_google(auth(email: 'ana.new@example.com', name: 'Ana B'))

      expect(described_class.count).to eq 1
      expect(user).to have_attributes(email: 'ana.new@example.com', name: 'Ana B')
    end

    it 'refuses an unverified email' do
      expect(described_class.from_google(auth(verified: false))).to be_nil
      expect(described_class.count).to eq 0
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
