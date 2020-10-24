require 'spec_helper'

describe "users/edit" do
  before(:each) do
    @user = assign(:user, FactoryGirl.create(:comercial))
  end

  it "renders the edit user form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => users_path(@user), :method => "post" do
      assert_select "input#user_email", :name => "user[email]"
      assert_select "input#user_role_ids_", :name => "user[role_ids]"
    end
  end
end
