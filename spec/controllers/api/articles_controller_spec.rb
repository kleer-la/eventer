# frozen_string_literal: true

require 'rails_helper'

describe Api::ArticlesController do
  describe "GET 'Articles/#' (/api/articles/#.<format>)" do
    it 'fetch a article' do
      ar = create(:article)
      get :show, params: { id: ar.id, format: 'json' }
      expect(assigns(:article)).to eq ar
    end

    it 'fetches an article with recommended content' do
      article = create(:article)
      recommended_article = create(:article)

      # Create a related content
      RecommendedContent.create(source: article, target: recommended_article, relevance_order: 50)

      get :show, params: { id: article.id, format: 'json' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response['id']).to eq(article.id)
      expect(json_response['title']).to eq(article.title)

      expect(json_response['recommended']).to be_an(Array)
      expect(json_response['recommended'].length).to eq(1)

      recommended_item = json_response['recommended'].first
      expect(recommended_item['id']).to eq(recommended_article.id)
      expect(recommended_item['title']).to eq(recommended_article.title)
      expect(recommended_item['subtitle']).to eq(recommended_article.description)
      expect(recommended_item['cover']).to eq(recommended_article.cover)
      expect(recommended_item['type']).to eq('article')
    end
  end
  describe "GET 'Articles' (/api/articles.<format>)" do
    it 'Articles list w/o body' do
      create(:article)

      get :index, params: { format: 'json' }
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response).not_to include('body')
    end
  end

  describe "GET 'show' (/article/1.<format>)" do
    it 'fetch a article json w/UPCASE' do
      article = create(:article)
      article.slug.upcase!
      get :show, params: { id: article.to_param, format: 'json' }
      expect(assigns(:article)).to eq article
      expect(response.content_type).to eq('application/json; charset=utf-8')
    end
  end
end
