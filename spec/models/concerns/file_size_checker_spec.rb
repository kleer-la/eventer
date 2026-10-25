# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileSizeChecker do
  subject(:checker) { Class.new { include FileSizeChecker }.new }

  it 'reads the size from a HEAD request' do
    stub_request(:head, 'https://kleer-images.s3.sa-east-1.amazonaws.com/cover.png')
      .to_return(headers: { 'Content-Length' => '1234' })

    expect(checker.get_remote_file_size('https://kleer-images.s3.sa-east-1.amazonaws.com/cover.png')).to eq(1234)
  end

  it 'resolves a relative path against www.kleer.la' do
    stub_request(:head, 'https://www.kleer.la/app/img/cover.png')
      .to_return(headers: { 'Content-Length' => '99' })

    expect(checker.get_remote_file_size('/app/img/cover.png')).to eq(99)
  end

  # Brakeman SSLVerify: the HEAD request used to turn certificate checks off.
  it 'verifies the server certificate' do
    stub_request(:head, 'https://www.kleer.la/cover.png').to_return(headers: { 'Content-Length' => '1' })
    verify_modes = []
    allow_any_instance_of(Net::HTTP).to receive(:verify_mode=).and_wrap_original do |original, mode|
      verify_modes << mode
      original.call(mode)
    end

    checker.get_remote_file_size('https://www.kleer.la/cover.png')

    expect(verify_modes).not_to include(OpenSSL::SSL::VERIFY_NONE)
  end
end
