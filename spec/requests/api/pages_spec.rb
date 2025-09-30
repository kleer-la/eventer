# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Pages', type: :request do
  describe 'GET /api/pages/:id' do
    let(:page) do
      Page.create!(
        name: 'Test Page',
        slug: 'test-page',
        lang: 'en',
        seo_title: 'Test SEO Title',
        seo_description: 'Test SEO Description',
        canonical: '/test-page',
        cover: 'https://example.com/cover.jpg'
      )
    end

    let!(:section1) do
      Section.create!(
        page: page,
        title: 'First Section',
        content: 'First section content',
        cta_text: 'Click Here',
        cta_url: 'https://example.com/click',
        position: 1
      )
    end

    let!(:section2) do
      Section.create!(
        page: page,
        title: 'Second Section',
        content: 'Second section content',
        cta_text: 'Learn More',
        cta_url: 'https://example.com/learn',
        position: 2
      )
    end

    context 'when page exists' do
      it 'returns the page with sections including cta_url' do
        get "/api/pages/#{page.to_param}"

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        expect(json_response['seo_title']).to eq('Test SEO Title')
        expect(json_response['seo_description']).to eq('Test SEO Description')
        expect(json_response['lang']).to eq('en')
        expect(json_response['canonical']).to eq('/test-page')
        expect(json_response['cover']).to eq('https://example.com/cover.jpg')

        expect(json_response['sections'].size).to eq(2)

        first_section = json_response['sections'].find { |s| s['position'] == 1 }
        expect(first_section['title']).to eq('First Section')
        expect(first_section['content']).to eq('First section content')
        expect(first_section['cta_text']).to eq('Click Here')
        expect(first_section['cta_url']).to eq('https://example.com/click')
        expect(first_section['slug']).to eq('first-section')

        second_section = json_response['sections'].find { |s| s['position'] == 2 }
        expect(second_section['title']).to eq('Second Section')
        expect(second_section['content']).to eq('Second section content')
        expect(second_section['cta_text']).to eq('Learn More')
        expect(second_section['cta_url']).to eq('https://example.com/learn')
        expect(second_section['slug']).to eq('second-section')
      end

      it 'handles sections without cta_url' do
        section_without_url = Section.create!(
          page: page,
          title: 'Third Section',
          content: 'Third section content',
          cta_text: 'No URL',
          position: 3
        )

        get "/api/pages/#{page.to_param}"

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        third_section = json_response['sections'].find { |s| s['position'] == 3 }
        expect(third_section['cta_text']).to eq('No URL')
        expect(third_section['cta_url']).to be_nil
      end
    end

    context 'when page does not exist' do
      it 'returns 404 not found' do
        get '/api/pages/non-existent-page'

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Page not found')
      end
    end
  end
end
