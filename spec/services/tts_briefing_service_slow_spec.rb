# frozen_string_literal: true

require 'rails_helper'

# Real ffprobe and ffmpeg (the `apad` + concat chain); only edge-tts, which needs
# the network, is replaced by a sine tone of the same shape. Needs ffmpeg installed.
describe TtsBriefingService, slow: true do
  def tool?(name) = system('which', name, out: File::NULL, err: File::NULL)

  before do
    skip 'ffmpeg and ffprobe are not installed' unless tool?('ffmpeg') && tool?('ffprobe')

    original = Open3.method(:capture3)
    allow(Open3).to receive(:capture3) do |*args|
      tool_args = args.drop(4) # `timeout -k <grace> <seconds>`
      if tool_args.first == 'edge-tts'
        media = tool_args[tool_args.index('--write-media') + 1]
        original.call('ffmpeg', '-y', '-f', 'lavfi', '-i', 'sine=frequency=440:duration=1', '-c:a', 'libmp3lame', media)
      else
        original.call(*args)
      end
    end
  end

  def mp3_duration(bytes)
    Tempfile.create(['briefing', '.mp3']) do |file|
      file.binmode.write(bytes)
      file.flush
      out, = Open3.capture2('ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', file.path)
      Float(out)
    end
  end

  it 'pads each beat to its floor and concatenates them' do
    mp3 = described_class.call(beats: [{ 'narration' => 'Uno', 'duration' => 3 },
                                       { 'narration' => 'Dos', 'duration' => 2 }])

    expect(mp3_duration(mp3)).to be_within(0.5).of(5)
  end

  it 'adds only the breath to a beat with no floor' do
    mp3 = described_class.call(beats: [{ 'narration' => 'Uno' }])

    expect(mp3_duration(mp3)).to be_within(0.3).of(1.35)
  end
end
