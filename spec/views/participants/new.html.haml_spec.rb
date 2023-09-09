# frozen_string_literal: true

require 'rails_helper'

describe 'participants/new' do
  before(:each) do
    @event = FactoryBot.create(:event)
    @participant = Participant.new
    @influence_zones = InfluenceZone.sort_wo_republica
    @participant.event = @event
    I18n.locale = :es
    @nakedform = false

    assign(:participant, @participant)
  end

  it 'renders the new template' do
    render
    expect(response).to render_template('new')
  end

  it 'matches the expected content' do
    render
    expect(response.body).to match(/2 personas/)
  end
end
