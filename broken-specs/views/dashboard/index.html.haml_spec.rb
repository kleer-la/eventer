require 'spec_helper'

# describe "dashboard/index.html.haml" do
#   before(:each) do
#     assign(:events, [
#       stub_model(Event,
#         :event_type => FactoryBot.build(:event_type),
#         :place => "Place",
#         :date => "2015-01-01",
#         :capacity => 20,
#         :city => "City",
#         :country => FactoryBot.build(:country),
#         :trainer => FactoryBot.build(:trainer),
#         :visibility_type => "Type",
#         :list_price => "9.99",
#         :list_price_plus_tax => false,
#         :list_price_2_pax_discount => 15,
#         :list_price_3plus_pax_discount => 25,
#         :eb_price => "19.99",
#         :draft => true,
#         :cancelled => false,
#         :is_webinar => false
#       ),
#       stub_model(Event,
#         :event_type => FactoryBot.build(:event_type),
#         :place => "Place",
#         :date => "2015-01-01",
#         :capacity => 20,
#         :city => "City",
#         :country => FactoryBot.build(:country),
#         :trainer => FactoryBot.build(:trainer),
#         :visibility_type => "Type",
#         :list_price => "9.99",
#         :list_price_plus_tax => false,
#         :list_price_2_pax_discount => 15,
#         :list_price_3plus_pax_discount => 25,
#         :eb_price => "19.99",
#         :draft => false,
#         :cancelled => false,
#         :is_webinar => false
#       )
#     ])
#   end

#   it "renders a list of events" do
#     I18n.locale = :es
#     render
#     assert_select "a>b", :text => "Tipo de Evento de Prueba", :count => 2
#     assert_select "small.pull-right", :text => "N/A", :count => 2
#   end
# end
