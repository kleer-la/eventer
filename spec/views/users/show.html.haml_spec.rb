require 'rails_helper'

describe "users/show" do
  before(:each) do
    @user = assign(:user, FactoryBot.create(:comercial))
  end

  it "show attributes " do
    render
    expect(rendered).to match(/comercial@user.com/)
    expect(rendered).to match(/comercial/)
  end
end
