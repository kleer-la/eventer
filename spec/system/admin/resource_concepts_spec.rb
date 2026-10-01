# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin concepts of a resource', type: :system do
  include Devise::Test::IntegrationHelpers

  let!(:resource) { create(:resource, format: :concepts, title_es: 'Conceptos de IA') }

  before do
    driven_by(:rack_test)
    sign_in create(:admin_user)
    create(:resource_concept, resource:, slug: 'datos', name: 'Datos de entrenamiento', stage: 'Cómo se fabrica')
  end

  it 'adds a card from the resource page, picking a stage already used' do
    visit admin_resource_path(resource)
    expect(page).to have_content('Datos de entrenamiento')
    click_link 'Edit concepts'
    expect(page).to have_content('Cómo se fabrica')

    click_link 'New Resource Concept'
    fill_in 'Name', with: 'Token'
    fill_in 'Slug', with: 'token'
    fill_in 'Question', with: '¿Qué es un token?'
    fill_in 'Stage', with: 'Qué pasa cuando le escribís'
    fill_in 'Definition', with: 'La unidad en que el modelo lee y escribe.'
    fill_in 'Related slugs', with: 'datos'
    expect(page).to have_css('datalist#concept-stages option[value="Cómo se fabrica"]', visible: :all)
    find('input[type=submit]').click

    expect(page).to have_content('¿Qué es un token?')
    expect(resource.concepts.find_by(slug: 'token')).to have_attributes(stage: 'Qué pasa cuando le escribís',
                                                                        related: ['datos'])
  end

  it 'edits a card and filters the list by language' do
    create(:resource_concept, resource:, slug: 'token', name: 'Token', lang: 'en')

    visit admin_resource_resource_concepts_path(resource, q: { lang_eq: 'en' })
    expect(page).not_to have_content('Datos de entrenamiento')

    visit admin_resource_resource_concepts_path(resource)
    within('tr', text: 'Datos de entrenamiento') { find('a.edit_link').click }
    fill_in 'Practice', with: 'Pasale la fuente.'
    find('input[type=submit]').click

    expect(resource.concepts.find_by(slug: 'datos').practice).to eq('Pasale la fuente.')
  end
end
