# frozen_string_literal: true

require 'rails_helper'

describe 'rendering new participant form' do
  pending 'Buy button' do
    @event= FactoryBot.create(:event)
    @participant = Participant.new
    @participant.event = @event
    @nakedform = false
    assign(:influence_zones, [FactoryBot.create(:influence_zone)])

    render template: 'patticipants/new' # , :action => 'new',:layout => "empty_layout"

    expect(rendered).to match(/Juan Carlos/)
  end
end
