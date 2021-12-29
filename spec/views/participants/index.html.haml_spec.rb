# frozen_string_literal: true

require 'rails_helper'

describe 'participants/index' do
  before(:each) do
    @event = FactoryBot.create(:event)
    FactoryBot.create(:participant, fname: 'P Name 1', id: 1, event: @event)
    FactoryBot.create(:participant, fname: 'P Name 2', id: 2, event: @event)

    assign(:participants, @event.participants)
  end

  it 'renders a list of trainers' do
    @influence_zones = InfluenceZone.all
    @status_valuekey = [%w[Nuevo N], %w[Contactado T]]

    render

    expect(rendered).to match(/P Name 1/)
    expect(rendered).to match(/P Name 2/)
  end
end
