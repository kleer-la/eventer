# frozen_string_literal: true

require 'rails_helper'

describe HandoffToken do
  let(:user) { create(:handoff_user) }

  describe '.issue!' do
    it 'returns the token once and stores only its digest' do
      token = described_class.issue!(user)

      expect(token.plaintext).to match(/\Akh_[1-9A-HJ-NP-Za-km-z]{32}\z/)
      expect(token.digest).to eq Digest::SHA256.hexdigest(token.plaintext)
      expect(described_class.pluck(:digest).join).not_to include(token.plaintext)
    end

    it 'revokes the previous active token of the same user' do
      old = described_class.issue!(user)
      described_class.issue!(user)

      expect(old.reload).to be_revoked
      expect(user.handoff_tokens.active.count).to eq 1
    end
  end

  describe '.authenticate' do
    it 'finds the active token and records when it was used' do
      token = described_class.issue!(user)

      found = described_class.authenticate(token.plaintext)

      expect(found).to eq token
      expect(found.last_used_at).to be_within(2.seconds).of(Time.current)
    end

    it 'is nil for a revoked token, an unknown token or a blank one' do
      token = described_class.issue!(user)
      token.revoke!

      expect(described_class.authenticate(token.plaintext)).to be_nil
      expect(described_class.authenticate('kh_nope')).to be_nil
      expect(described_class.authenticate('')).to be_nil
    end
  end
end
