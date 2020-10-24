require 'spec_helper'

describe "users/index" do
  before(:each) do
    assign(:users, [FactoryGirl.create(:administrator),FactoryGirl.create(:comercial)])
  end

  it "renders a list of users" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "admin@user.com".to_s, :count => 1
    assert_select "tr>td", :text => "comercial@user.com".to_s, :count => 1
    assert_select "tr>td", :text => "administrator".to_s, :count => 1
    assert_select "tr>td", :text => "comercial".to_s, :count => 1
  end
end
