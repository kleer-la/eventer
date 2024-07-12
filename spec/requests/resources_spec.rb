# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/resources', type: :request do
  describe 'GET /index' do
    it 'renders a successful response' do
      FactoryBot.create(:resource)
      get resources_url
      expect(response).to be_successful
    end
  end

  # describe 'GET /show' do
  #   it 'renders a successful response' do
  #     article = FactoryBot.create(:article)
  #     get article_url(article)
  #     expect(response).to be_successful
  #   end
  #   it 'one article has trainer json ' do
  #     article = FactoryBot.create(:article)
  #     trainer = FactoryBot.create(:trainer, name: 'Luke')
  #     article.trainers << trainer
  #     get article_url(article), params: { id: article.to_param, format: 'json' }

  #     article_json = @response.parsed_body
  #     expect(article_json['trainers'].count).to be 1
  #     expect(article_json['trainers'][0]['name']).to eq 'Luke'
  #   end
  # end

  # describe 'GET /new' do
  #   it 'renders a successful response' do
  #     get new_article_url
  #     expect(response).to be_successful
  #   end
  # end

  # describe 'GET /edit' do
  #   it 'render a successful response' do
  #     article = FactoryBot.create(:article)
  #     get edit_article_url(article)
  #     expect(response).to be_successful
  #   end
  # end

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'creates a new Resource' do
        expect do
          post resources_url, params: { resource: FactoryBot.attributes_for(:resource) }
        end.to change(Resource, :count).by(1)
      end

      it 'redirects to the created resource' do
        post resources_url, params: { resource: FactoryBot.attributes_for(:resource) }
        expect(response).to redirect_to(edit_resource_path(Resource.last))
      end
      it 'has common fields ' do
        post resources_url, params: { resource: FactoryBot.attributes_for(:resource) }
        expect(Resource.last.format).to eq 'card'
        expect(Resource.last.slug).to start_with 'resource-'
      end
      it 'has basic _es fields ' do
        post resources_url, params: { resource: FactoryBot.attributes_for(:resource) }
        expect(Resource.last.title_es).to eq 'Mi recurso'
        expect(Resource.last.description_es).to eq 'My resource'
        expect(Resource.last.landing_es).to eq '/blog/my-resource'
        expect(Resource.last.cover_es).to eq 'my-resource.png'
      end
      it 'has extra _es fields ' do
        post resources_url, params: { resource: FactoryBot.attributes_for(:resource,
                                                                          share_link_es: 'link',
                                                                          share_text_es: 'text',
                                                                          tags_es: 'tags',
                                                                          comments_es: 'comments') }
        expect(Resource.last.share_link_es).to eq 'link'
        expect(Resource.last.share_text_es).to eq 'text'
        expect(Resource.last.tags_es).to eq 'tags'
        expect(Resource.last.comments_es).to eq 'comments'
      end

      it 'has basic _en fields ' do
        post resources_url, params: { resource: FactoryBot.attributes_for(:resource,
                                                                          share_link_es: 'link',
                                                                          share_text_es: 'text',
                                                                          tags_es: 'tags',
                                                                          comments_es: 'comments') }
        expect(Resource.last.share_link_es).to eq 'link'
        expect(Resource.last.share_text_es).to eq 'text'
        expect(Resource.last.tags_es).to eq 'tags'
        expect(Resource.last.comments_es).to eq 'comments'
      end
      it 'has extra _es fields ' do
        post resources_url, params: { resource: FactoryBot.attributes_for(:resource,
                                                                          title_en: 'title',
                                                                          description_en: 'description',
                                                                          landing_en: 'landing',
                                                                          cover_en: 'cover') }
        expect(Resource.last.title_en).to eq 'title'
        expect(Resource.last.description_en).to eq 'description'
        expect(Resource.last.landing_en).to eq 'landing'
        expect(Resource.last.cover_en).to eq 'cover'
      end
      it 'has extra _en fields ' do
        post resources_url, params: { resource: FactoryBot.attributes_for(:resource,
                                                                          share_link_en: 'link',
                                                                          share_text_en: 'text',
                                                                          tags_en: 'tags',
                                                                          comments_en: 'comments') }
        expect(Resource.last.share_link_en).to eq 'link'
        expect(Resource.last.share_text_en).to eq 'text'
        expect(Resource.last.tags_en).to eq 'tags'
        expect(Resource.last.comments_en).to eq 'comments'
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Resource' do
        expect do
          post resources_url, params: { resource: FactoryBot.attributes_for(:resource, title_es: '') }
        end.to change(Resource, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post resources_url, params: { resource: FactoryBot.attributes_for(:resource, title_es: '') }
        expect(response).to be_successful
      end
    end
  end

  describe 'PATCH /update' do
    context 'with valid parameters' do
      it 'updates the requested article' do
        resource = FactoryBot.create(:resource)
        patch resource_url(resource), params: { resource: FactoryBot.attributes_for(:resource, title_es: 'new title') }
        resource.reload
        expect(resource.title_es).to eq 'new title'
      end

      #     it 'redirects to the article' do
      #       article = FactoryBot.create(:article)
      #       patch article_url(article), params: { article: FactoryBot.attributes_for(:article, title: 'new title') }
      #       article.reload
      #       expect(response).to redirect_to(edit_article_path(article))
      #     end
      #     it 'lang-> en' do
      #       article = FactoryBot.create(:article)
      #       patch article_url(article), params: { article: FactoryBot.attributes_for(:article, lang: 'en') }
      #       article.reload
      #       expect(article.lang).to eq('en')
      #     end
      #   end

      #   context 'with invalid parameters' do
      #     it "renders a successful response (i.e. to display the 'edit' template)" do
      #       article = FactoryBot.create(:article)
      #       patch article_url(article), params: { article: FactoryBot.attributes_for(:article, title: '') }
      #       expect(response).to be_successful
      #     end
    end
  end

  # describe 'DELETE /destroy' do
  #   it 'destroys the requested article' do
  #     article = FactoryBot.create(:article)
  #     expect do
  #       delete article_url(article)
  #     end.to change(Article, :count).by(-1)
  #   end

  #   it 'redirects to the articles list' do
  #     article = FactoryBot.create(:article)
  #     delete article_url(article)
  #     expect(response).to redirect_to(articles_url)
  # end
  # end
end
