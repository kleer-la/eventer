# frozen_string_literal: true

require 'rails_helper'

# Runs the real ImageMagick: mini_magick shells out to `magick`, so this is
# also the check that the binary (not only the library) is installed.
describe ImageConversionService do
  # A 1x1 PNG
  let(:png_bytes) do
    Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==')
  end
  let(:png) do
    file = Tempfile.new(['source', '.png'], binmode: true)
    file.write(png_bytes)
    file.flush
    file
  end

  after { png.close! }

  it 'converts a PNG into a WebP file' do
    webp_path = described_class.convert_to_webp(png.path)

    expect(File.binread(webp_path, 12)).to match(/\ARIFF.{4}WEBP/m)
  ensure
    FileUtils.rm_f(webp_path.to_s)
  end

  it 'refuses formats it does not convert' do
    gif = Tempfile.new(['source', '.gif'])
    expect { described_class.convert_to_webp(gif.path) }.to raise_error(ArgumentError, /Unsupported/)
  end

  it 'names the twin after the original' do
    expect(described_class.webp_filename('blog/portada final.PNG')).to eq 'portada final.webp'
    expect(described_class.supported_for_webp?('x.jpeg')).to be true
    expect(described_class.supported_for_webp?('x.gif')).to be false
  end
end
