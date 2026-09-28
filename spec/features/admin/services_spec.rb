# frozen_string_literal: true

require 'rails_helper'

# A missed permit_params drops a field on save in silence, and a show row that
# renders nothing hides what was saved.
RSpec.describe 'Admin services', type: :feature do
  let(:administrator) { create(:administrator) }
  let!(:service) { create(:service) }

  before { login_as(administrator, scope: :user) }

  it 'saves the hero image from the form and shows it' do
    visit edit_admin_service_path(service)
    fill_in 'Hero image', with: 'https://example.com/hero.webp'
    find("input[type='submit']").click

    expect(service.reload.hero_image).to eq 'https://example.com/hero.webp'
    expect(page).to have_css("img[src='https://example.com/hero.webp']")
  end
end
