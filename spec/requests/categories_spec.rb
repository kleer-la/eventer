# frozen_string_literal: true

require 'rails_helper'

describe 'API Categories GET /categories', type: :request do
  context 'category list in json' do
    # pending "add some examples for json to (or delete) #{__FILE__}"
    before(:example) do
      @category = FactoryBot.create(:category, visible: true, name: 'org')
      @url = '/api/categories.json'
      get @url
      @json = JSON.parse(response.body)
    end
    it 'ok json?' do
      expect(response).to be_successful
      expect(@json.size).to eq 1
    end

    it 'one visible category' do
      FactoryBot.create(:category, visible: false)
      get @url
      json = JSON.parse(response.body)
      expect(json.size).to eq 1
      expect(json[0]['name']).to eq 'org'
    end
  end
end
