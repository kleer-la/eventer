# frozen_string_literal: true

require 'rails_helper'

describe Api::PagesController do
  describe "GET 'pages/:id' (api/pages/:id.json)" do
    let!(:page) do
      Page.create!(name: 'About', lang: :es, template: 'overlay',
                   seo_title: 'Sobre', seo_description: 'Acerca de')
    end

    it 'serializes template and show_in_footer' do
      get :show, params: { id: page.to_param, format: 'json' }
      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json['template']).to eq('overlay')
      expect(json['show_in_footer']).to be false
    end

    it 'serves a flagship page with sections' do
      flag = Page.create!(name: 'Flagship', lang: :es, template: 'flagship', show_in_footer: true)
      Section.create!(page: flag, slug: 'hero', title: 'Hero', content: '<p>welcome</p>', position: 1)
      Section.create!(page: flag, slug: 'pricing', title: 'Precios',
                      content: '<div class="rw-pricing">cards</div>', position: 2)

      get :show, params: { id: flag.to_param, format: 'json' }
      json = JSON.parse(response.body)
      expect(json['template']).to eq('flagship')
      expect(json['show_in_footer']).to be true
      slugs = json['sections'].map { |s| s['slug'] }
      expect(slugs).to contain_exactly('hero', 'pricing')
    end
  end

  describe "GET 'pages/footer' (api/pages/footer.json)" do
    before do
      Page.create!(name: 'Membresia IA', lang: :es, slug: 'membresia-ia',
                   template: 'flagship', show_in_footer: true)
      Page.create!(name: 'Sobre Nosotros', lang: :es, show_in_footer: false)
    end

    it 'returns only pages flagged for the footer' do
      get :footer, format: 'json'
      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json.size).to eq(1)
      expect(json.first).to include('name' => 'Membresia IA', 'slug' => 'membresia-ia', 'lang' => 'es')
    end
  end
end
