# frozen_string_literal: true

require 'rails_helper'
require 'open3'

# Production eager-loads app/, so whatever loads at boot is paid in every Puma
# worker and in the job process (#237). These specs boot the app the same way,
# in a fresh process, and list which of the given constants ended up defined.
RSpec.describe 'Boot memory' do
  def constants_loaded_at_boot(names)
    probe = <<~RUBY
      Rails.application.eager_load!
      puts #{names.inspect}.select { |c| Object.const_defined?(c) }.join(',')
    RUBY
    out, err, status = Open3.capture3({ 'RAILS_ENV' => 'test' }, 'bin/rails', 'runner', probe,
                                      chdir: Rails.root.to_s)
    expect(status).to be_success, err
    out.lines.last.to_s.strip
  end

  # A gem required at the top of an app file loads at boot even with
  # `require: false` in the Gemfile; heavy, rarely used ones must not.
  it 'does not load heavy, rarely used gems' do
    expect(constants_loaded_at_boot(%w[XeroRuby Gruff Google::Apis EventMachine Daemons])).to eq('')
  end

  # config/application.rb requires only the frameworks the app uses, not
  # rails/all: nothing receives inbound email or opens a websocket.
  it 'does not load Rails frameworks the app does not use' do
    expect(constants_loaded_at_boot(%w[ActionMailbox ActionCable])).to eq('')
  end
end
