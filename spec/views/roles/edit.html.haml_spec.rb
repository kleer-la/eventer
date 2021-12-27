# frozen_string_literal: true

require 'rails_helper'

describe 'roles/edit' do
  before(:each) do
    @role = assign(:role,
                   FactoryBot.create(:admin_role, name: 'R Name 1'))
  end

  it 'renders the edit role form' do
    render

    expect(rendered).to match(/R Name 1/)
  end
end
