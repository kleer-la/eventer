# frozen_string_literal: true

require 'rails_helper'

# The area carries the blocks a service has, so it can be sold on its own. The
# admin has to let them in: a missed permit_params drops a field on save in
# silence, and a show row that renders nothing hides what was saved.
RSpec.describe 'Admin service areas', type: :feature do
  let(:administrator) { create(:administrator) }
  let!(:area) { create(:service_area, name: 'Adopción de IA') }

  before { login_as(administrator, scope: :user) }

  it 'saves the pricing and the brochure from the form' do
    visit edit_admin_service_area_path(area)
    fill_in 'Pricing', with: 'Desde USD 5.000'
    fill_in 'Brochure', with: 'https://example.com/adopcion-ia.pdf'
    find("input[type='submit']").click

    area.reload
    expect(area.pricing).to eq('Desde USD 5.000')
    expect(area.brochure).to eq('https://example.com/adopcion-ia.pdf')
  end

  it 'offers the offering blocks and the recommended contents in the form' do
    visit new_admin_service_area_path

    # Rich text inputs are Trix editors, not form fields Capybara can see: check their labels
    %w[Outcomes Definitions Program Faq].each { |block| expect(page).to have_css('label', text: block) }
    expect(page).to have_field('Pricing').and have_field('Brochure')
    expect(page).to have_content('Recommended Contents')
  end

  it 'shows the offering blocks it has' do
    area.update!(outcomes: '<ul><li>Equipos que usan IA a diario</li></ul>',
                 program: '<ol><li>Diagnóstico<ul><li>Dos semanas</li></ul></li></ol>',
                 pricing: 'Desde USD 5.000', brochure: 'https://example.com/adopcion-ia.pdf')

    visit admin_service_area_path(area)

    expect(page).to have_content('Equipos que usan IA a diario')
    expect(page).to have_content('Diagnóstico').and have_content('Dos semanas')
    expect(page).to have_content('Desde USD 5.000')
    expect(page).to have_link('https://example.com/adopcion-ia.pdf')
  end
end
