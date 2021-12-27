# frozen_string_literal: true

require 'rails_helper'

describe 'users/edit' do
  before(:each) do
    @user = assign(:user, FactoryBot.create(:comercial))
  end

  it 'renders the edit user form' do
    render

    expect(rendered).to match(/comercial@user.com/)
    expect(rendered).to match(/comercial/)
  end
end
