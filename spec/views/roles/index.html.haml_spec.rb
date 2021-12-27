# frozen_string_literal: true

require 'rails_helper'

describe 'roles/index' do
  before(:each) do
    assign(:roles, [
             FactoryBot.create(:admin_role, name: 'R Name 1'),
             FactoryBot.create(:comercial_role, name: 'R Name 2')
           ])
  end

  it 'renders a list of roles' do
    render

    expect(rendered).to match(/R Name 1/)
    expect(rendered).to match(/R Name 2/)
  end
end
