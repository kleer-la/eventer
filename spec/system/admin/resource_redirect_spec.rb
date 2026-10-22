# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin redirect of a resource', type: :system do
  include Devise::Test::IntegrationHelpers

  let!(:resource) { create(:resource, published: false) }

  before do
    driven_by(:rack_test)
    sign_in create(:admin_user)
  end

  it 'is set from the edit form and shown on the resource page' do
    visit edit_admin_resource_path(resource)
    fill_in 'Redirect url', with: '/es/recursos/otro'
    find('input[type=submit]').click

    expect(resource.reload.redirect_url).to eq '/es/recursos/otro'
    expect(page).to have_link('/es/recursos/otro')
  end

  it 'refuses a value that is neither a path nor a URL' do
    visit edit_admin_resource_path(resource)
    fill_in 'Redirect url', with: 'otro'
    find('input[type=submit]').click

    expect(page).to have_content('must be a path')
    expect(resource.reload.redirect_url).to be_nil
  end
end
