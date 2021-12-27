# frozen_string_literal: true

require 'rails_helper'

describe 'rendering for report survey responses' do
  it 'displays the participant list' do
    participant = FactoryBot.create(:participant)
    assign(:participants, [participant])
    assign(:event, participant.event)

    render template: 'participants/survey'

    expect(rendered).to match(/Juan Carlos/)
  end
  it 'displays a message for an empty participant list' do
    assign(:participants, [])
    assign(:event, FactoryBot.create(:event))

    render template: 'participants/survey'

    expect(rendered).to match(/No hay participantes/)
  end
end
