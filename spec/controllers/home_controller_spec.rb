# frozen_string_literal: true

require 'rails_helper'

describe HomeController do
  describe "GET 'index' (/api/events.<format>)" do
    it 'returns http success' do
      get :index, params: { format: 'json' }
      expect(response).to be_successful
    end
    it 'returns events' do
      FactoryBot.create(:event, currency_iso_code: 'USD')
      get :index, params: { format: 'json' }
      json_response = JSON.parse(response.body)
      expect(json_response.count).to eq 1
      expect(json_response[0]['currency_iso_code']).to eq 'USD'
    end
    it 'dont returns draft events' do
      FactoryBot.create(:event, place: 'here')
      FactoryBot.create(:event, place: 'there', draft: true)
      get :index, params: { format: 'json' }
      json_response = JSON.parse(response.body)
      expect(json_response.count).to eq 1
      expect(json_response[0]['place']).to eq 'here'
    end
  end

  # TODO: is it used?
  describe "GET 'show' (/api/events.<format>)" do
    it 'fetch a course' do
      event = FactoryBot.create(:event, place: 'here')
      get :show, params: { id: event.to_param, format: 'json' }
      json_response = JSON.parse(response.body)
      expect(json_response['place']).to eq 'here'
    end
  end

  describe 'contact us' do
    ['hola', 'Peter', 'Bruce Lee', 'PEter'].each do |name|
      it "#{name} is a valid name" do
        expect(HomeController.valid_name?(name)).to be true
      end
    end
    [
      ['', 'empty'],
      ['skyreveryLiz', 'uppercase not first char'],
      ['FjqDTZHrLzJWQ ', 'internal uppercase'],
      ["HeyaMr...: ) the passive income it's 999eu a day C'mon -", 'too long']
    ].each do |ex|
      it "name <#{ex[0]}> is invalid. Reason: #{ex[1]} " do
        expect(HomeController.valid_name?(ex[0])).to be false
      end
    end
    ['please help me'].each do |message|
      it "#{message} is a valid message" do
        expect(HomeController.valid_message?(message)).to be true
      end
    end
    [
      ['', '', 'empty'],
      ['go to http://phising.com', 'http://', 'url w/ http']
    ].each do |(msg, _filter, reason)|
      it "message <#{msg}> is invalid. Reason: #{reason} " do
        expect(HomeController.valid_message?(msg)).to be false
      end
    end

    [
      ['Papa', 'e@ma.il', '/', '', 'hi there']
    ].each do |(name, email, context, subject, message)|
      it "Contact is valid (#{name},#{email},#{context},#{subject},#{message},)" do
        expect(HomeController.valid_contact_us(name, email, context, subject, message, nil, '')).to be nil
      end
    end
    [
      ['aPPa', '', '', '', '', '', 'bad name'],
      ['Papa', '', '', '', '', '', 'bad message'],
      ['Papa', '', '', '', 'hi there', '', 'empty email'],
      ['Papa', 'e@ma.il', '', '', 'hi there', '', 'empty context'],
      ['Papa', 'e@ma.il\n', '', '', 'hi there', '', 'invalid email'],
      ['Papa', 'e@ma.il', '/', '',
       '¿Aún no eres millonario? ¡El robot financiero te convertirá en él! http://go.hojagoak.com/0j35', 'http', 'bad message'],
      ['Papa', 'e@ma.il', '/', 'oops', 'hi there', '', 'subject honeypot']
    ].each do |(name, email, context, subject, message, filter, error)|
      it "Contact is invalid (#{name},#{email},#{context},#{subject},#{message},). Reason: #{error} " do
        expect(HomeController.valid_contact_us(name, email, context, subject, message, nil, filter)).to eq error
      end
    end
  end
end
