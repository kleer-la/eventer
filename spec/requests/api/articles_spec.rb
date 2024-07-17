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
    it 'articles has trainer json ' do
      article = create(:article)
      trainer = create(:trainer, name: 'Luke')
      article.trainers << trainer
      get api_articles_path, params: { format: :json }

      article_json = @response.parsed_body
      expect(article_json[0]['trainers'].count).to be 1
      expect(article_json[0]['trainers'][0]['name']).to eq 'Luke'
    end
    it 'articles has category json ' do
      article = create(:article, category: create(:category, name: 'Republic'))
      get api_articles_path, params: { format: :json }

      article_json = @response.parsed_body
      expect(article_json[0]['category_id']).to be article.category.id
      expect(article_json[0]['category_name']).to eq 'Republic'
    end
    it 'articles has abstract json ' do
      create(:article, body: 'some text')
      get api_articles_path, params: { format: :json }

      article_json = @response.parsed_body
      expect(article_json[0]['abstract']).to eq 'some text'
    end
  end
end
