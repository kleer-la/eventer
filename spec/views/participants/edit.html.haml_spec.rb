# frozen_string_literal: true

require 'rails_helper'

describe 'participants/edit' do
  before(:each) do
    @participant = assign(:participant,
                          FactoryBot.create(:participant, fname: 'P Name'))
  end

  it 'renders the edit trainer form' do
    @event = @participant.event # Event.find(params[:event_id])
    @influence_zones = InfluenceZone.all
    @status_valuekey = [%w[Nuevo N], %w[Contactado T]]

    render

    expect(rendered).to match(/P Name/)
  end
end
