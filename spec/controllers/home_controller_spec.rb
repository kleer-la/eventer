# frozen_string_literal: true

require 'rails_helper'

describe HomeController do
  describe "GET 'index' (/api/events.<format>)" do
    it 'returns http success' do
      get :index, params: { format: 'xml' }
      expect(response).to be_successful
    end
    it 'returns events' do
      event = FactoryBot.create(:event)
      get :index, params: { format: 'xml' }
      expect(assigns(:events)).to eq [event]
    end
    it 'returns non draft events' do
      FactoryBot.create(:event, place: 'here')
      FactoryBot.create(:event, place: 'there', draft: true)
      get :index, params: { format: 'xml' }
      expect(assigns(:events).map(&:place)).to eq ['here']
    end
  end

  describe "GET 'show' (/api/events.<format>)" do
    it 'fetch a course' do
      event = FactoryBot.create(:event)
      get :show, params: { id: event.to_param, format: 'xml' }
      expect(assigns(:event)).to eq event
    end
    it 'illegal course not found' do
      expect do
        get :show, params: { id: 1 }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
    it 'draft course found' do
      event = FactoryBot.create(:event, draft: false)
      get :show, params: { id: event.to_param, format: 'xml' }
      expect(assigns(:event)).to eq event
    end
  end

  describe "GET 'event_types' (/api/event_types/#.<format>)" do
    it 'fetch a event_type' do
      et = FactoryBot.create(:event_type)
      get :event_type_show, params: { id: et.to_param, format: 'json' }
      expect(assigns(:event_type)).to eq et
    end
    it 'fetch a event_type' do
      et = FactoryBot.create(:event_type)
      ev = FactoryBot.create(:event, event_type: et)
      FactoryBot.create(:participant, event: ev, testimony: 'Hello, Joe', selected: true)

      get :event_type_show, params: { id: et.to_param, format: 'json' }
      expect(assigns(:event_type)).to eq et
    end
  end

  describe 'contact us' do
    ['hola', 'Peter', 'Bruce Lee', 'PEter'].each do |name|
      it "#{name} is a valid name" do
        expect(HomeController.valid_name?(name)).to be true
      end
    end
    [ ['', 'empty'],
      ['skyreveryLiz', 'uppercase not first char'],
      ['FjqDTZHrLzJWQ ', 'internal uppercase'],
      ["HeyaMr...: ) the passive income it's 999eu a day C'mon -", 'too long'],
    ].each do |ex|
      it "name <#{ex[0]}> is invalid. Reason: #{ex[1]} " do
        expect(HomeController.valid_name?(ex[0])).to be false
      end
    end
    [ ['Papa', 'e@ma.il', '/', '', 'hi there'],
    ].each do |(name, email, context, subject, message)|
      it "Contact is valid (#{name},#{email},#{context},#{subject},#{message},)" do
        expect(HomeController.valid_contact_us(name, email, context, subject, message, nil)).to be nil
      end
    end
    [ ['aPPa', '', '', '', '', 'bad name'],
      ['Papa', '', '', '', '', 'empty message'],
      ['Papa', '', '', '', 'hi there', 'empty email'],
      ['Papa', 'e@ma.il', '', '', 'hi there', 'empty context'],
      ['Papa', 'e@ma.il', '/', 'oops', 'hi there', 'subject honeypot'],
    ].each do |(name, email, context, subject, message, error)|
      it "Contact is invalid (#{name},#{email},#{context},#{subject},#{message},). Reason: #{error} " do
        expect(HomeController.valid_contact_us(name, email, context, subject, message, nil)).to eq error
      end
    end
  end
end
