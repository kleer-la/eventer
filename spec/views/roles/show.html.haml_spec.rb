# frozen_string_literal: true

require 'rails_helper'

describe 'roles/show' do
  before(:each) do
    @role = assign(:role,
                   FactoryBot.create(:admin_role, name: 'R Name'))
  end

  it 'renders attributes in <p>' do
    render
    expect(rendered).to match(/R Name/)
  end
end
