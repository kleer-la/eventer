# frozen_string_literal: true

require 'rails_helper'

describe 'users/new' do
  before(:each) do
    assign(:user, User.new)
  end

  it 'renders new user form' do
    render

    expect(rendered).to match(/E-mail/)
    expect(rendered).to match(/Clave/)
  end
end
