# frozen_string_literal: true

require 'rails_helper'

describe 'roles/new' do
  before(:each) do
    assign(:role, Role.new)
  end

  it 'renders new role form' do
    render

    expect(rendered).to match(/Nombre/)
  end
end
