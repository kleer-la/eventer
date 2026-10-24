# frozen_string_literal: true

require 'rails_helper'
require 'open3'

# Production eager-loads app/, so a gem required at the top of an app file is
# loaded in every Puma worker even if Gemfile says `require: false`. Heavy gems
# used in one or two places must stay out of the boot (#237).
RSpec.describe 'Boot memory' do
  it 'does not load heavy, rarely used gems when the app eager-loads' do
    probe = <<~RUBY
      Rails.application.eager_load!
      puts %w[XeroRuby Gruff Google::Apis EventMachine Daemons].select { |c| Object.const_defined?(c) }.join(',')
    RUBY

    out, err, status = Open3.capture3({ 'RAILS_ENV' => 'test' }, 'bin/rails', 'runner', probe,
                                      chdir: Rails.root.to_s)

    expect(status).to be_success, err
    expect(out.lines.last.to_s.strip).to eq('')
  end
end
