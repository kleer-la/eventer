require 'rails_helper'

RSpec.describe "rendering new participant form" do
  pending "Buy button" do
    @event= FactoryBot.create(:event)
    @participant= Participant.new
    @influence_zones= [FactoryBot.create(:influence_zone)]
    @nakedform= false

    render 
    # (
    #     :template => "/participants/new", 
    #     :formats=> :html )


    # expect(rendered).to match /Juan Carlos/
  end
 
end
