# frozen_string_literal: true

require 'rails_helper'

describe TtsBriefingService do
  let(:ok_status) { instance_double(Process::Status, success?: true) }
  let(:calls) { [] }
  let(:wrapped_calls) { [] }

  def timeouts = wrapped_calls.map { |wrapped| Float(wrapped[3]) }

  def beats(*narrations)
    narrations.map { |narration| { 'narration' => narration } }
  end

  # Every tool runs under coreutils `timeout -k <grace> <seconds> <tool> …`.
  def unwrap(wrapped)
    expect(wrapped.first).to eq 'timeout'
    wrapped.drop(4)
  end

  # Pretend edge-tts, ffprobe and ffmpeg ran: write whatever file the tool was
  # given as its output, and answer ffprobe with a fixed duration.
  before do
    allow(Open3).to receive(:capture3) do |*wrapped|
      wrapped_calls << wrapped
      args = unwrap(wrapped)
      calls << args
      case args.first
      when 'edge-tts'
        File.binwrite(args[args.index('--write-media') + 1], 'x' * 4000)
      when 'ffprobe'
        next ["1.2\n", '', ok_status]
      when 'ffmpeg'
        File.binwrite(args.last, 'y' * 4000)
      end
      ['', '', ok_status]
    end
  end

  it 'synthesizes each beat and concatenates them into one mp3' do
    mp3 = described_class.call(beats: beats('Hola', 'Mundo'))

    expect(mp3).to be_present
    expect(calls.count { |a| a.first == 'edge-tts' }).to eq 2
  end

  it 'uses the default voice and rate' do
    described_class.call(beats: beats('Hola'))

    edge_call = calls.find { |a| a.first == 'edge-tts' }
    expect(edge_call).to include("--voice=#{TtsBriefingService::DEFAULT_VOICE}",
                                 "--rate=#{TtsBriefingService::DEFAULT_RATE}")
  end

  it 'honors a voice and rate override' do
    described_class.call(beats: beats('Hola'), voice: 'en-US-JennyNeural', rate: '+0%')

    edge_call = calls.find { |a| a.first == 'edge-tts' }
    expect(edge_call).to include('--voice=en-US-JennyNeural', '--rate=+0%')
  end

  it 'skips beats with blank narration' do
    described_class.call(beats: beats('Hola', '', '   '))

    edge_calls = calls.select { |a| a.first == 'edge-tts' }
    expect(edge_calls.size).to eq 1
    expect(edge_calls.first).to include('--text=Hola')
  end

  it 'passes values as --opt=value, so a narration or rate starting with a dash is not read as an option' do
    described_class.call(beats: beats('--help'), rate: '-20%')

    edge_call = calls.find { |a| a.first == 'edge-tts' }
    expect(edge_call).to include('--text=--help', '--rate=-20%')
  end

  it 'pads a beat to its duration floor, with a 0.35s breath on top of the audio' do
    described_class.call(beats: [{ 'narration' => 'Hola', 'duration' => 5 }])

    pad_call = calls.find { |a| a.first == 'ffmpeg' && a.include?('-af') }
    pad = pad_call[pad_call.index('-af') + 1][/pad_dur=([\d.]+)/, 1].to_f
    expect(pad).to be_within(0.01).of(3.8) # duration floor (5) minus the stubbed 1.2s of audio
  end

  it 'adds only the breath when there is no duration floor to reach' do
    described_class.call(beats: beats('Hola'))

    pad_call = calls.find { |a| a.first == 'ffmpeg' && a.include?('-af') }
    pad = pad_call[pad_call.index('-af') + 1][/pad_dur=([\d.]+)/, 1].to_f
    expect(pad).to be_within(0.01).of(0.35)
  end

  it 'caps an oversized duration floor so a beat cannot ask for unbounded silence' do
    described_class.call(beats: [{ 'narration' => 'Hola', 'duration' => 1_000_000 }])

    pad_call = calls.find { |a| a.first == 'ffmpeg' && a.include?('-af') }
    pad = pad_call[pad_call.index('-af') + 1][/pad_dur=([\d.]+)/, 1].to_f
    expect(pad).to be_within(0.01).of(TtsBriefingService::MAX_BEAT_SECONDS - 1.2)
  end

  it 'treats a negative duration floor as no floor' do
    described_class.call(beats: [{ 'narration' => 'Hola', 'duration' => -30 }])

    pad_call = calls.find { |a| a.first == 'ffmpeg' && a.include?('-af') }
    pad = pad_call[pad_call.index('-af') + 1][/pad_dur=([\d.]+)/, 1].to_f
    expect(pad).to be_within(0.01).of(0.35)
  end

  it 'rejects an empty beats list' do
    expect { described_class.call(beats: []) }.to raise_error(TtsBriefingService::Error, /non-empty/)
  end

  it 'rejects too many beats' do
    expect { described_class.call(beats: beats(*(['Hola'] * (TtsBriefingService::MAX_BEATS + 1)))) }
      .to raise_error(TtsBriefingService::Error, /at most/)
  end

  it 'rejects narration over the total character budget' do
    long = 'a' * (TtsBriefingService::MAX_TOTAL_CHARS + 1)
    expect { described_class.call(beats: beats(long)) }.to raise_error(TtsBriefingService::Error, /too long/)
  end

  it 'rejects a beats list where every beat is empty' do
    expect { described_class.call(beats: beats('', '  ')) }.to raise_error(TtsBriefingService::Error, /narration/)
  end

  it 'rejects a malformed voice' do
    expect { described_class.call(beats: beats('Hola'), voice: 'drop table;') }
      .to raise_error(TtsBriefingService::Error, /invalid voice/)
  end

  it 'raises when edge-tts fails' do
    fail_status = instance_double(Process::Status, success?: false, exitstatus: 1)
    allow(Open3).to receive(:capture3).with('timeout', '-k', anything, anything, 'edge-tts', any_args)
                                      .and_return(['', 'network error', fail_status])

    expect { described_class.call(beats: beats('Hola')) }.to raise_error(TtsBriefingService::Error, /edge-tts failed/)
  end

  describe 'tool failures' do
    let(:fail_status) { instance_double(Process::Status, success?: false, exitstatus: 1) }
    let(:logged) { [] }

    before do
      allow(Open3).to receive(:capture3).with('timeout', '-k', anything, anything, 'edge-tts', any_args)
                                        .and_return(['', 'Traceback: secret narration Hola /tmp/x', fail_status])
      allow(Rails.logger).to receive(:error) { |message| logged << message }
    end

    it 'does not put the tool stderr in the error message' do
      expect { described_class.call(beats: beats('Hola')) }
        .to raise_error(TtsBriefingService::Error) { |e| expect(e.message).not_to include('Traceback', '/tmp') }
    end

    it 'logs the failing tool and its exit status, but not the narration' do
      expect { described_class.call(beats: beats('Hola')) }.to raise_error(TtsBriefingService::Error)

      expect(logged).to include(match(/edge-tts.*exit 1/))
      expect(logged.join).not_to include('Hola')
    end
  end

  it 'reports a tool killed by its timeout as such' do
    timed_out = instance_double(Process::Status, success?: false, exitstatus: 124)
    allow(Open3).to receive(:capture3).with('timeout', '-k', anything, anything, 'edge-tts', any_args)
                                      .and_return(['', '', timed_out])

    expect { described_class.call(beats: beats('Hola')) }.to raise_error(TtsBriefingService::Error, /timed out/)
  end

  it 'gives each tool a timeout no longer than what is left of the overall budget' do
    described_class.call(beats: beats('Hola'))

    expect(timeouts).to all(be_between(1, TtsBriefingService::MAX_SYNTHESIS_SECONDS))
  end

  it 'stops starting new tools once the overall budget is spent' do
    stub_const('TtsBriefingService::MAX_SYNTHESIS_SECONDS', 0)

    expect { described_class.call(beats: beats('Hola', 'Mundo')) }
      .to raise_error(TtsBriefingService::Error, /too long/)
  end

  describe 'malformed input' do
    it 'rejects beats that are not an array' do
      expect { described_class.call(beats: { 'narration' => 'Hola' }) }
        .to raise_error(TtsBriefingService::Error, /array/)
    end

    it 'rejects a beat that is not a hash' do
      expect { described_class.call(beats: ['Hola', 3, nil]) }.to raise_error(TtsBriefingService::Error, /hash/)
    end

    it 'rejects a narration that is not a string' do
      expect { described_class.call(beats: [{ 'narration' => ['Hola'] }]) }
        .to raise_error(TtsBriefingService::Error, /narration must be a string/)
    end

    it 'rejects a voice that is not a string' do
      expect { described_class.call(beats: beats('Hola'), voice: ['es-AR-ElenaNeural']) }
        .to raise_error(TtsBriefingService::Error, /voice/)
    end

    it 'rejects a rate that is not a string' do
      expect { described_class.call(beats: beats('Hola'), rate: { 'a' => 1 }) }
        .to raise_error(TtsBriefingService::Error, /rate/)
    end

    it 'rejects a malformed rate, as it does a malformed voice' do
      expect { described_class.call(beats: beats('Hola'), rate: '--help') }
        .to raise_error(TtsBriefingService::Error, /invalid rate/)
    end

    it 'accepts signed percentage rates' do
      %w[+0% -20% +100%].each do |rate|
        expect { described_class.call(beats: beats('Hola'), rate: rate) }.not_to raise_error
      end
    end

    it 'treats a duration that is not a number as no floor' do
      expect { described_class.call(beats: [{ 'narration' => 'Hola', 'duration' => 'abc' }]) }.not_to raise_error
    end

    it 'raises the service error when ffprobe answers N/A' do
      allow(Open3).to receive(:capture3).with('timeout', '-k', anything, anything, 'ffprobe', any_args)
                                        .and_return(["N/A\n", '', ok_status])

      expect { described_class.call(beats: beats('Hola')) }.to raise_error(TtsBriefingService::Error, /duration/)
    end
  end
end
