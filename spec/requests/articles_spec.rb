# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/articles', type: :request do
  describe 'GET /index' do
    it 'renders a successful response' do
      FactoryBot.create(:article)
      get articles_url
      expect(response).to be_successful
    end
    it 'articles has trainer json ' do
      article = FactoryBot.create(:article)
      trainer = FactoryBot.create(:trainer, name: 'Luke')
      article.trainers << trainer
      get articles_url, params: { format: 'json' }

      article_json = @response.parsed_body
      expect(article_json[0]['trainers'].count).to be 1
      expect(article_json[0]['trainers'][0]['name']).to eq 'Luke'
    end
    it 'articles has category json ' do
      article = FactoryBot.create(:article, category: FactoryBot.create(:category, name: 'Republic'))
      get articles_url, params: { format: 'json' }

      article_json = @response.parsed_body
      expect(article_json[0]['category_id']).to be article.category.id
      expect(article_json[0]['category_name']).to eq 'Republic'
    end
    it 'articles has abstract json ' do
      FactoryBot.create(:article, body: 'some text')
      get articles_url, params: { format: 'json' }

      article_json = @response.parsed_body
      expect(article_json[0]['abstract']).to eq 'some text'
    end
  end

  describe 'GET /show' do
    it 'renders a successful response' do
      article = FactoryBot.create(:article)
      get article_url(article)
      expect(response).to be_successful
    end
    it 'one article has trainer json ' do
      article = FactoryBot.create(:article)
      trainer = FactoryBot.create(:trainer, name: 'Luke')
      article.trainers << trainer
      get article_url(article), params: { id: article.to_param, format: 'json' }

      article_json = @response.parsed_body
      expect(article_json['trainers'].count).to be 1
      expect(article_json['trainers'][0]['name']).to eq 'Luke'
    end
  end

  describe 'GET /new' do
    it 'renders a successful response' do
      get new_article_url
      expect(response).to be_successful
    end
  end

  describe 'GET /edit' do
    it 'render a successful response' do
      article = FactoryBot.create(:article)
      get edit_article_url(article)
      expect(response).to be_successful
    end
  end

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'creates a new Article' do
        expect do
          post articles_url, params: { article: FactoryBot.attributes_for(:article) }
        end.to change(Article, :count).by(1)
      end

      it 'redirects to the created article' do
        post articles_url, params: { article: FactoryBot.attributes_for(:article) }
        expect(response).to redirect_to(article_url(Article.last))
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Article' do
        expect do
          post articles_url, params: { article: FactoryBot.attributes_for(:article, title: '') }
        end.to change(Article, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post articles_url, params: { article: FactoryBot.attributes_for(:article, title: '') }
        expect(response).to be_successful
      end
    end
  end

  describe 'PATCH /update' do
    context 'with valid parameters' do
      it 'updates the requested article' do
        article = FactoryBot.create(:article)
        patch article_url(article), params: { article: FactoryBot.attributes_for(:article, title: 'new title') }
        article.reload
        expect(article.title).to eq 'new title'
      end

      it 'redirects to the article' do
        article = FactoryBot.create(:article)
        patch article_url(article), params: { article: FactoryBot.attributes_for(:article, title: 'new title') }
        article.reload
        expect(response).to redirect_to(edit_article_path(article))
      end
      it 'lang-> en' do
        article = FactoryBot.create(:article)
        patch article_url(article), params: { article: FactoryBot.attributes_for(:article, lang: 'en') }
        article.reload
        expect(article.lang).to eq('en')
      end
    end

    context 'with invalid parameters' do
      it "renders a successful response (i.e. to display the 'edit' template)" do
        article = FactoryBot.create(:article)
        patch article_url(article), params: { article: FactoryBot.attributes_for(:article, title: '') }
        expect(response).to be_successful
      end
    end
  end

  describe 'DELETE /destroy' do
    it 'destroys the requested article' do
      article = FactoryBot.create(:article)
      expect do
        delete article_url(article)
      end.to change(Article, :count).by(-1)
    end

    it 'redirects to the articles list' do
      article = FactoryBot.create(:article)
      delete article_url(article)
      expect(response).to redirect_to(articles_url)
    end
  end
end
