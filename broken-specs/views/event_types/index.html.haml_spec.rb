# encoding: utf-8

require 'spec_helper'

describe "event_types/index" do
  before(:each) do
    assign(:event_types, [
      stub_model(EventType,
        :name => "Tipo de evento 1",
        :duration => 8,
        :description => "La descripción del tipo de evento 1",
        :recipients => "Los destinatarios del tipo de evento 1",
        :program => "El programa del tipo de evento 1"
      ),
      stub_model(EventType,
        :name => "Tipo de evento 2",
        :duration => 8,
        :description => "La descripción del tipo de evento 2",
        :recipients => "Los destinatarios del tipo de evento 2",
        :program => "El programa del tipo de evento 2"
      )
    ])
  end

  it "renders a list of event_types" do
    render
    assert_select "tr>th", :text => "Tipo de Evento".to_s, :count => 1
    #assert_select "tr>th", :text => "Descripción".to_s, :count => 1
    assert_select "tr>td", :text => "Tipo de evento 1".to_s, :count => 1
    assert_select "tr>td", :text => "Tipo de evento 2".to_s, :count => 1
    #assert_select "tr>td", :text => "La descripción del tipo de evento 1".to_s, :count => 1
    #assert_select "tr>td", :text => "La descripción del tipo de evento 2".to_s, :count => 1
  end
end
