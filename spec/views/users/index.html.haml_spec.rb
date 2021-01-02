require 'rails_helper'

describe "users/index" do
  before(:each) do
    assign(:users, [FactoryBot.create(:administrator),FactoryBot.create(:comercial)])
  end

  it "renders a list of users" do
    render
    expect(rendered).to match(/admin@user.com/)
    expect(rendered).to match(/comercial@user.com/)
    expect(rendered).to match(/administrator/)
    expect(rendered).to match(/comercial/)
  end
end
