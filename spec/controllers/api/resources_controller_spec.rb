# frozen_string_literal: true

require 'rails_helper'

describe Api::ResourcesController do
  describe "GET 'index' (/api/resources.<format>)" do
    it 'returns a list of resources ordered by creation date' do
      older_resource = create(:resource, created_at: 2.days.ago)
      newer_resource = create(:resource, created_at: 1.day.ago)

      get :index, params: { format: 'json' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response.first['id']).to eq(newer_resource.id)
      expect(json_response.second['id']).to eq(older_resource.id)
    end

    it 'includes resource basic fields' do
      resource = create(:resource,
                        title_es: 'Mi recurso especial',
                        description_es: 'Descripción del recurso',
                        cover_es: 'recurso-especial.png',
                        landing_es: '/blog/recurso-especial',
                        format: :card)

      get :index, params: { format: 'json' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      first_resource = json_response.first

      expect(first_resource['title_es']).to eq('Mi recurso especial')
      expect(first_resource['description_es']).to eq('Descripción del recurso')
      expect(first_resource['cover_es']).to eq('recurso-especial.png')
      expect(first_resource['landing_es']).to eq('/blog/recurso-especial')
      expect(first_resource['format']).to eq('card')
    end

    it 'includes all trainer types (authors, illustrators, translators)' do
      author = create(:trainer, name: 'Author Name')
      illustrator = create(:trainer, name: 'Illustrator Name')
      translator = create(:trainer, name: 'Translator Name')

      resource = create(:resource)

      # Create associations through join tables
      create(:authorship, resource:, trainer: author)
      create(:illustration, resource:, trainer: illustrator)
      create(:translation, resource:, trainer: translator)

      get :index, params: { format: 'json' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      first_resource = json_response.first

      # Verify authors array exists and has correct name
      expect(first_resource['authors']).to be_an(Array)
      author_response = first_resource['authors'].first
      expect(author_response['name']).to eq('Author Name')

      # Verify illustrators array exists and has correct name
      expect(first_resource['illustrators']).to be_an(Array)
      illustrator_response = first_resource['illustrators'].first
      expect(illustrator_response['name']).to eq('Illustrator Name')

      # Verify translators array exists and has correct name
      expect(first_resource['translators']).to be_an(Array)
      translator_response = first_resource['translators'].first
      expect(translator_response['name']).to eq('Translator Name')
    end
  end

  describe "GET 'show' (/api/resources/:id.<format>)" do
    it 'fetches a resource with all trainer associations' do
      author = create(:trainer,
                      name: 'Author Name',
                      bio: 'Author bio',
                      gravatar_email: 'author@example.com',
                      twitter_username: 'authortwitter',
                      linkedin_url: 'linkedin.com/author',
                      bio_en: 'Author English bio')

      resource = create(:resource,
                        title_es: 'Mi recurso único',
                        description_es: 'Descripción única',
                        cover_es: 'recurso-unico.png',
                        landing_es: '/blog/recurso-unico')

      create(:authorship, resource:, trainer: author)

      get :show, params: { id: resource.to_param, format: 'json' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      # Resource fields
      expect(json_response['id']).to eq(resource.id)
      expect(json_response['title_es']).to eq('Mi recurso único')
      expect(json_response['description_es']).to eq('Descripción única')
      expect(json_response['cover_es']).to eq('recurso-unico.png')
      expect(json_response['landing_es']).to eq('/blog/recurso-unico')

      # Author fields
      author_response = json_response['authors'].first
      expect(author_response['name']).to eq('Author Name')
    end

    it 'returns 404 for non-existent resource' do
      get :show, params: { id: 'non-existent', format: 'json' }

      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Resource not found')
    end

    it 'handles friendly id slugs' do
      resource = create(:resource, title_es: 'Mi Recurso Test')
      get :show, params: { id: resource.slug, format: 'json' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(resource.id)
    end
    it 'includes long_description and preview in the response' do
      resource = create(:resource,
                        long_description_es: 'Descripción extendida del recurso en español',
                        long_description_en: 'Extensive resource description in English',
                        preview_es: 'https://example.com/preview-es.png',
                        preview_en: 'https://example.com/preview-en.png')

      get :show, params: { id: resource.to_param, format: 'json' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response['long_description_es']).to eq('Descripción extendida del recurso en español')
      expect(json_response['long_description_en']).to eq('Extensive resource description in English')
      expect(json_response['preview_es']).to eq('https://example.com/preview-es.png')
      expect(json_response['preview_en']).to eq('https://example.com/preview-en.png')
    end
  end

  describe 'GET #preview' do
    before do
      @published_resource = create(:resource, title_es: 'Published Resource', published: true)
      @unpublished_resource = create(:resource, title_es: 'Unpublished Resource', published: false)
    end

    it 'returns all resources including unpublished ones in JSON format' do
      get :preview, params: { format: 'json' }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      resource_titles = json_response.map { |item| item['title_es'] }
      expect(resource_titles).to include('Published Resource')
      expect(resource_titles).to include('Unpublished Resource')
    end

    it 'orders resources by created_at descending' do
      # Clean up any existing resources first
      Resource.delete_all
      
      old_unpublished = create(:resource,
                              title_es: 'Old Unpublished Resource',
                              created_at: 1.month.ago,
                              published: false)
      new_published = create(:resource,
                            title_es: 'New Published Resource',
                            created_at: 1.day.ago,
                            published: true)

      get :preview, params: { format: 'json' }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      
      # Should be ordered by created_at desc (newest first)
      expect(json_response.first['title_es']).to eq('New Published Resource')
      expect(json_response.last['title_es']).to eq('Old Unpublished Resource')
    end

    it 'includes the same fields and associations as index' do
      category = create(:category, name: 'Preview Category')
      author = create(:trainer, name: 'Preview Author')
      resource = create(:resource, 
                       title_es: 'Preview Resource Test', 
                       published: false,
                       category: category)
      create(:authorship, resource:, trainer: author)

      get :preview, params: { format: 'json' }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      preview_resource = json_response.find { |r| r['title_es'] == 'Preview Resource Test' }

      expect(preview_resource).to be_present
      expect(preview_resource['category_name']).to eq('Preview Category')
      expect(preview_resource['authors']).to be_an(Array)
      expect(preview_resource['authors'].first['name']).to eq('Preview Author')
      expect(preview_resource['translators']).to be_an(Array)
      expect(preview_resource['illustrators']).to be_an(Array)
    end
  end
end
