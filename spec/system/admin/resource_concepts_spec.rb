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

  # The concepts screen is out of the menu, and the panel that links to it sits
  # at the bottom of the page: the title bar reaches it from view and edit.
  it 'reaches the concepts from the title bar of the resource view and edit' do
    [admin_resource_path(resource), edit_admin_resource_path(resource)].each do |path|
      visit path
      within('#titlebar_right') { click_link 'Concepts' }

      expect(page).to have_current_path(admin_resource_resource_concepts_path(resource))
    end
  end

  it 'offers no Concepts button on a resource of another format' do
    card = create(:resource, format: :card)

    visit admin_resource_path(card)

    within('#titlebar_right') { expect(page).not_to have_link('Concepts') }
  end

  it 'explains the link mark on the text fields and rejects a link that goes nowhere' do
    visit edit_admin_resource_resource_concept_path(resource, resource.concepts.first)
    expect(page).to have_content('[[slug|texto]]')

    fill_in 'Practice', with: 'Ver [[nada]].'
    find('input[type=submit]').click

    expect(page).to have_content('nada')
    expect(resource.concepts.first.practice).to be_blank
  end
end
