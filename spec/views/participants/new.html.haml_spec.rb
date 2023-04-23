# frozen_string_literal: true

require 'rails_helper'

describe 'rendering new participant form' do
  pending 'Buy button' do
    @event= FactoryBot.create(:event)
    @participant = Participant.new
    @influence_zones = InfluenceZone.sort_wo_republica
    @participant.event = @event
    I18n.locale = :es
    @nakedform = false
    # @quantities = ParticipantsController.quantities_list
    # TODO: move quantities_list to ParticipantsHelper

    render template: 'participants/new' # , :action => 'new',:layout => "empty_layout"

    expect(rendered).to match(/Juan Carlos/)
  end
end
