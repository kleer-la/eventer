require 'spec_helper'

describe "users/show" do
  before(:each) do
    @user = assign(:user, FactoryGirl.create(:comercial))
  end

  it "renders attributes in <p>" do
    render
    rendered.should match(/comercial@user.com/)
    rendered.should match(/comercial/)
  end
end
