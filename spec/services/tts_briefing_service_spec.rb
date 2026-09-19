# frozen_string_literal: true

require 'rails_helper'

describe TtsBriefingService do
  let(:ok_status) { instance_double(Process::Status, success?: true) }
  let(:calls) { [] }

  def beats(*narrations)
    narrations.map { |narration| { 'narration' => narration } }
  end

  # Pretend edge-tts, ffprobe and ffmpeg ran: write whatever file the tool was
  # given as its output, and answer ffprobe with a fixed duration.
  before do
    allow(Open3).to receive(:capture3) do |*args|
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
    expect(edge_call).to include('--voice', TtsBriefingService::DEFAULT_VOICE,
                                 '--rate', TtsBriefingService::DEFAULT_RATE)
  end

  it 'honors a voice and rate override' do
    described_class.call(beats: beats('Hola'), voice: 'en-US-JennyNeural', rate: '+0%')

    edge_call = calls.find { |a| a.first == 'edge-tts' }
    expect(edge_call).to include('--voice', 'en-US-JennyNeural', '--rate', '+0%')
  end

  it 'skips beats with blank narration' do
    described_class.call(beats: beats('Hola', '', '   '))

    edge_calls = calls.select { |a| a.first == 'edge-tts' }
    expect(edge_calls.size).to eq 1
    expect(edge_calls.first).to include('Hola')
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
    fail_status = instance_double(Process::Status, success?: false)
    allow(Open3).to receive(:capture3).with('edge-tts', any_args).and_return(['', 'network error', fail_status])

    expect { described_class.call(beats: beats('Hola')) }.to raise_error(TtsBriefingService::Error, /edge-tts failed/)
  end
end
