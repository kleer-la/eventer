# frozen_string_literal: true

require 'rails_helper'

# POST /api/tts/briefing carries the narration of an arbitrary work session; it
# must not end up in the request log (see #198).
describe 'filter_parameter_logging' do
  let(:filter) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }

  it 'filters the briefing narration' do
    params = {
      'beats' => [{ 'narration' => 'client X is about to churn', 'duration' => '5' }],
      'voice' => 'es-AR-ElenaNeural'
    }

    filtered = filter.filter(params)

    expect(filtered.to_s).not_to include('client X')
    expect(filtered['voice']).to eq 'es-AR-ElenaNeural'
  end
end
