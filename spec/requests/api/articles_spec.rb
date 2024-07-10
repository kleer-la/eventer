# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::ArticlesController', type: :request do
  describe 'GET /articles' do
    it 'one article has trainer json ' do
      article = FactoryBot.create(:article)
      trainer = FactoryBot.create(:trainer, name: 'Luke')
      article.trainers << trainer
      get api_article_path(article, format: :json)

      expect(response.content_type).to eq('application/json; charset=utf-8')

      article_json = @response.parsed_body
      expect(article_json['trainers'].count).to be 1
      expect(article_json['trainers'][0]['name']).to eq 'Luke'
    end
  end
end
