# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/articles', type: :request do
  describe 'GET /index' do
    it 'renders a successful response' do
      create(:article)
      get articles_url
      expect(response).to be_successful
    end
  end

  describe 'GET /show' do
    it 'renders a successful response' do
      article = create(:article)
      get article_url(article)
      expect(response).to be_successful
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
      article = create(:article)
      get edit_article_url(article)
      expect(response).to be_successful
    end
  end

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'creates a new Article' do
        expect do
          post articles_url, params: { article: attributes_for(:article) }
        end.to change(Article, :count).by(1)
      end

      it 'redirects to the created article' do
        post articles_url, params: { article: attributes_for(:article) }
        expect(response).to redirect_to(edit_article_path(Article.last))
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Article' do
        expect do
          post articles_url, params: { article: attributes_for(:article, title: '') }
        end.to change(Article, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post articles_url, params: { article: attributes_for(:article, title: '') }
        expect(response).to be_successful
      end
    end
  end

  describe 'PATCH /update' do
    context 'with valid parameters' do
      it 'updates the requested article' do
        article = create(:article)
        patch article_url(article), params: { article: attributes_for(:article, title: 'new title') }
        article.reload
        expect(article.title).to eq 'new title'
      end

      it 'redirects to the article' do
        article = create(:article)
        patch article_url(article), params: { article: attributes_for(:article, title: 'new title') }
        article.reload
        expect(response).to redirect_to(edit_article_path(article))
      end
      it 'lang-> en' do
        article = create(:article)
        patch article_url(article), params: { article: attributes_for(:article, lang: 'en') }
        article.reload
        expect(article.lang).to eq('en')
      end
    end

    context 'with invalid parameters' do
      it "renders a successful response (i.e. to display the 'edit' template)" do
        article = create(:article)
        patch article_url(article), params: { article: attributes_for(:article, title: '') }
        expect(response).to be_successful
      end
    end
  end

  describe 'DELETE /destroy' do
    it 'destroys the requested article' do
      article = create(:article)
      expect do
        delete article_url(article)
      end.to change(Article, :count).by(-1)
    end

    it 'redirects to the articles list' do
      article = create(:article)
      delete article_url(article)
      expect(response).to redirect_to(articles_url)
    end
  end
end
