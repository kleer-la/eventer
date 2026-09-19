# frozen_string_literal: true

require 'rails_helper'

describe TtsUsage do
  def admit(beats_count: 1, chars: 100, client: nil, owner: nil)
    described_class.admit!(beats_count: beats_count, chars: chars, client: client, owner: owner)
  end

  def set(key, value)
    Setting.find_or_initialize_by(key: key).update!(value: value.to_s)
  end

  def record(status: 'ok', chars: 100, at: Time.current, client: nil, owner: nil)
    described_class.create!(status: status, beats_count: 1, chars: chars, created_at: at, client_hash: client,
                            owner_id: owner&.id)
  end

  describe '.admit!' do
    it 'records a running usage when under every limit' do
      usage = admit(beats_count: 3, chars: 250)

      expect(usage).to be_persisted
      expect(usage).to have_attributes(status: 'running', beats_count: 3, chars: 250)
    end

    it 'denies with 503 when the kill switch is off' do
      set('TTS_ENABLED', 'false')

      expect { admit }.to raise_error(TtsUsage::Denied) { |e| expect(e.status).to eq 503 }
      expect(described_class.count).to eq 0
    end

    context 'with the hourly briefing limit' do
      before { set('TTS_MAX_BRIEFINGS_PER_HOUR', 2) }

      it 'denies with 429 and a Retry-After once the limit is reached' do
        record(at: 50.minutes.ago)
        record(at: 10.minutes.ago)

        expect { admit }.to raise_error(TtsUsage::Denied) { |e|
          expect(e.status).to eq 429
          expect(e.retry_after).to be_within(5).of(10.minutes)
        }
      end

      it 'ignores usages older than an hour' do
        record(at: 2.hours.ago)
        record(at: 90.minutes.ago)

        expect { admit }.not_to raise_error
      end
    end

    context 'with the daily character limit' do
      before { set('TTS_MAX_CHARS_PER_DAY', 1000) }

      it 'denies with 429 when this briefing would go over' do
        record(chars: 900, at: 3.hours.ago)

        expect { admit(chars: 200) }.to raise_error(TtsUsage::Denied) { |e| expect(e.status).to eq 429 }
      end

      it 'admits a briefing that fits exactly' do
        record(chars: 900, at: 3.hours.ago)

        expect { admit(chars: 100) }.not_to raise_error
      end
    end

    context 'with the concurrency cap' do
      before { set('TTS_MAX_CONCURRENCY', 1) }

      it 'denies with 503 while another synthesis is running, and leaves no row behind' do
        record(status: 'running')

        expect { admit }.to raise_error(TtsUsage::Denied) { |e|
          expect(e.status).to eq 503
          expect(e.retry_after).to be_positive
        }
        expect(described_class.where(status: 'running').count).to eq 1
      end

      it 'does not count a stale running row (a crashed request)' do
        record(status: 'running', at: 10.minutes.ago)

        expect { admit }.not_to raise_error
      end
    end

    it 'stores the client hash with the usage' do
      expect(admit(client: 'abcd1234abcd1234').client_hash).to eq 'abcd1234abcd1234'
    end

    context 'with the per-client hourly limit' do
      before { set('TTS_MAX_BRIEFINGS_PER_HOUR_PER_CLIENT', 1) }

      it 'denies one client with 429 without touching the others' do
        record(client: 'aaaa', at: 5.minutes.ago)

        expect { admit(client: 'aaaa') }.to raise_error(TtsUsage::Denied) { |e| expect(e.status).to eq 429 }
        expect { admit(client: 'bbbb') }.not_to raise_error
      end

      it 'does not apply to a usage with no client' do
        record(client: nil, at: 5.minutes.ago)

        expect { admit(client: nil) }.not_to raise_error
      end
    end

    context 'with the monthly per-user quota' do
      let(:user) { create(:handoff_user) }

      before { set('TTS_MAX_BRIEFINGS_PER_MONTH_PER_USER', 2) }

      it 'stores the owner with the usage' do
        expect(admit(owner: user).owner_id).to eq user.id
      end

      it 'denies with 429 and a Retry-After that reaches next month once the quota is used' do
        record(owner: user)
        record(owner: user, status: 'error')

        expect { admit(owner: user) }.to raise_error(TtsUsage::Denied) { |e|
          expect(e.status).to eq 429
          expect(e.retry_after).to be_within(60).of(Time.current.next_month.beginning_of_month - Time.current)
        }
      end

      it 'ignores last month and other users' do
        record(owner: user, at: 5.weeks.ago)
        record(owner: create(:handoff_user, email: 'b@example.com', google_uid: 'g-2'))

        expect { admit(owner: user) }.not_to raise_error
      end

      it 'does not apply to the internal shared secret (no owner)' do
        record(owner: nil)
        record(owner: nil)

        expect { admit(owner: nil) }.not_to raise_error
      end
    end

    it 'does not count errors as free: a failed synthesis still burned CPU' do
      set('TTS_MAX_BRIEFINGS_PER_HOUR', 1)
      record(status: 'error')

      expect { admit }.to raise_error(TtsUsage::Denied) { |e| expect(e.status).to eq 429 }
    end

    it 'has sane defaults when no Setting exists' do
      expect(Setting.where("key LIKE 'TTS_%'")).to be_empty
      expect { admit }.not_to raise_error
    end
  end

  describe '.client_hash_for' do
    it 'is stable for one IP, different across IPs, and not the IP itself' do
      a = described_class.client_hash_for('203.0.113.7')

      expect(a).to eq described_class.client_hash_for('203.0.113.7')
      expect(a).not_to eq described_class.client_hash_for('203.0.113.8')
      expect(a).to match(/\A\h{16}\z/)
    end

    it 'is nil for a blank IP' do
      expect(described_class.client_hash_for(nil)).to be_nil
    end
  end

  describe '.limits' do
    it 'lists every Setting key with its effective value and default' do
      set('TTS_MAX_CONCURRENCY', 5)

      limits = described_class.limits
      concurrency = limits.find { |l| l[:key] == 'TTS_MAX_CONCURRENCY' }

      expect(limits.map { |l| l[:key] }).to include('TTS_ENABLED', 'TTS_MAX_BRIEFINGS_PER_HOUR',
                                                    'TTS_MAX_BRIEFINGS_PER_HOUR_PER_CLIENT',
                                                    'TTS_MAX_CHARS_PER_DAY', 'TTS_MAX_CONCURRENCY',
                                                    'TTS_MAX_BRIEFINGS_PER_MONTH_PER_USER')
      expect(concurrency).to include(value: 5, default: TtsUsage::DEFAULT_MAX_CONCURRENCY)
    end
  end

  describe '#finish!' do
    it 'marks the usage ok and stores how long the synthesis took' do
      usage = admit

      usage.finish!(:ok, synthesis_ms: 1234)

      expect(usage.reload).to have_attributes(status: 'ok', synthesis_ms: 1234)
    end

    it 'marks the usage as an error' do
      usage = admit

      usage.finish!(:error, synthesis_ms: 50)

      expect(usage.reload.status).to eq 'error'
    end
  end
end
