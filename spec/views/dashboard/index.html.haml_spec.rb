require 'rails_helper'

describe "dashboard/index.html.haml" do
  before(:each) do
    assign(:events, [
        FactoryBot.create(:event),
        FactoryBot.create(:event)
    ])
  end

  it "renders a list of events" do
    render

    expect(rendered.scan("Tipo de Evento de Prueba").length).to eq 2
  end
end