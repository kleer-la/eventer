# encoding: utf-8

require 'rails_helper'

describe "event_types/index" do
  before(:each) do
    assign(:event_types, [
      FactoryBot.create(:event_type,
        :name => "First event type",
        :subtitle => "catchy sentence"
      ),
      FactoryBot.create(:event_type,
        :name => "Second event type"
      )
    ])
  end

  it "renders a list of event_types" do
    render

    expect(rendered.scan("Tipo de Evento").length).to eq 1
    expect(rendered.scan("First event type").length).to eq 1
    expect(rendered.scan("catchy sentence").length).to eq 1
    expect(rendered.scan("Second event type").length).to eq 1
  end
end
