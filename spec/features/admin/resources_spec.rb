# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Resources', type: :feature do
  let(:administrator) { create(:administrator) }
  let(:category) { create(:category, name: 'Test Category') }
  let(:author) { create(:trainer, name: 'Juan Alberto', signature_credentials: 'Agile Coach & Trainer') }
  let(:translator) { create(:trainer, name: 'Juan Alberto 2', signature_credentials: 'Agile Coach & Trainer 2') }
  let(:illustrator) { create(:trainer, name: 'Juan Alberto 3', signature_credentials: 'Agile Coach & Trainer 3') }
  # let(:author) { create(:trainer) }
  # let(:translator) { create(:trainer) }
  # let(:illustrator) { create(:trainer) }

  before do
    login_as(administrator, scope: :user)
  end

  before do
    login_as(administrator, scope: :user)
  end

  describe 'index page' do
    it 'lists all resources' do
      resource1 = create(:resource,
                         title_es: 'Primer Recurso',
                         format: :book,
                         category: category)
      resource2 = create(:resource,
                         title_es: 'Segundo Recurso',
                         format: :guide)

      create(:authorship, resource: resource1, trainer: author)

      visit admin_resources_path

      expect(page).to have_content('Resources')
      expect(page).to have_content(resource1.title_es)
      expect(page).to have_content(resource2.title_es)
      expect(page).to have_content(resource1.category_name)
      expect(page).to have_content('None') # For resource2 with no category
    end

    # TODO: Fix this test
    # it works with rails spec SPEC=spec/features/admin/resources_spec.rb
    # but not with rspec ci
    # it 'allows filtering resources' do
    #   _resource = create(:resource, title_es: 'Filterable Resource', format: :book)

    #   visit admin_resources_path
    #   fill_in 'Title es', with: 'Filterable'
    #   # click_button 'Filter'
    #   within '.filter_form' do
    #     find('input[type="submit"][value="Filter"]').click
    #   end

    #   expect(page).to have_content('Filterable Resource')
    # end
  end

  describe 'show page' do
    let(:resource) do
      create(:resource,
             title_es: 'Test Resource ES',
             description_es: 'Test Description ES',
             format: :book,
             category: category,
             getit_es: 'http://example.com/download',
             cover_es: 'cover.jpg',
             landing_es: '/blog/test-resource',
             long_description_es: '# Test markdown')
    end

    before do
      create(:authorship, resource: resource, trainer: author)
      create(:translation, resource: resource, trainer: translator)
      create(:illustration, resource: resource, trainer: illustrator)
      visit admin_resource_path(resource)
    end

    it 'displays resource details' do
      expect(page).to have_content(resource.title_es)
      expect(page).to have_content(resource.description_es)
      expect(page).to have_content('book')
      expect(page).to have_content(category.name)
    end

    it 'displays trainer information' do
      # Use the panel structure to target the specific section
      within('.panel', text: 'Additional Info') do
        within('.panel_contents') do
          row_data = all('tr.row').map { |row| row.text }
          author_row = row_data.find { |text| text.include?('Authors') }
          expect(author_row).to include(author.name)

          translator_row = row_data.find { |text| text.include?('Translators') }
          expect(translator_row).to include(translator.name)

          illustrator_row = row_data.find { |text| text.include?('Illustrators') }
          expect(illustrator_row).to include(illustrator.name)
        end
      end
    end

    it 'renders markdown content' do
      expect(page).to have_css('h1', text: 'Test markdown')
    end

    it 'displays image references' do
      expect(page).to have_content(resource.cover_es)
    end
  end

  describe 'new/create' do
    before do
      category # ensure the category is created
      visit admin_resources_path
      click_link 'New Resource'
    end

    it 'allows creating a new resource' do
      fill_in 'Title es', with: 'Nuevo Recurso'
      fill_in 'Description es', with: 'Descripción de prueba'

      select 'Book', from: 'resource_format'
      select 'Test Category', from: 'resource_category_id'

      # within '#resource_authors_input' do
      #   # Find the checkbox by its ID and check it
      #   find("#resource_author_ids_#{author.id}").set(true)
      # end

      click_button 'Crear'

      expect(page).to have_content('Nuevo Recurso')
      expect(page).to have_content('Test Category')
      # expect(page).to have_content(author.name)
    end
  end

  describe 'edit/update' do
    let(:resource) { create(:resource, title_es: 'Título Antiguo', format: :book) }

    it 'allows updating an existing resource' do
      visit edit_admin_resource_path(resource)
      fill_in 'Title es', with: 'Título Actualizado'
      select 'Guide', from: 'Format' # Capitalized as shown in the output
      find('input[type="submit"]').click

      expect(page).to have_content('Título Actualizado')
      expect(page).to have_content('guide')
    end
  end

  describe 'recommended content' do
    it 'displays recommended content' do
      resource = create(:resource)
      recommended_resource = create(:resource, title_es: 'Recurso Recomendado')
      create(:recommended_content,
             source: resource,
             target: recommended_resource,
             relevance_order: 1)

      visit admin_resource_path(resource)

      within('.panel', text: 'Recommended Content') do
        within('.panel_contents table') do
          expect(page).to have_content('Recurso Recomendado')
          expect(page).to have_content('1') # relevance_order
        end
      end
    end
  end

  describe 'check sizes action' do
    before { WebMock.allow_net_connect! }
    after { WebMock.disable_net_connect!(allow_localhost: true) }

    it 'displays cover sizes for all resources' do
      resource = create(:resource, cover_es: 'cover.jpg')

      visit check_sizes_admin_resources_path

      expect(page).to have_content(resource.title_es)
      expect(page).to have_content(resource.cover_es)
    end
  end

  describe 'friendly id slugs' do
    it 'generates slug from title_es' do
      resource = create(:resource, title_es: 'Test Título')
      expect(resource.slug).to eq('test-titulo')
    end

    it 'allows finding resource by slug' do
      resource = create(:resource, title_es: 'Test Resource')
      visit admin_resource_path(resource.slug)
      expect(page).to have_content('Test Resource')
    end

    it 'strips whitespace from slug' do
      resource = create(:resource, title_es: 'Test Resource ', slug: ' test-resource ')
      expect(resource.slug).to eq('test-resource')
    end
  end
end
