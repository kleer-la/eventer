# frozen_string_literal: true

require 'rails_helper'

describe 'rendering new participant form' do
  pending 'Buy button' do
    @participant = Participant.new
    @participant.event = FactoryBot.create(:event)
    @nakedform = false
    assign(:event, @participant.event)
    assign(:influence_zones, [FactoryBot.create(:influence_zone)])

    render template: 'participants/new' # , :action => 'new',:layout => "empty_layout"

    expect(rendered).to match(/Juan Carlos/)
  end
end
