require 'rails_helper'

RSpec.describe "articles/index", type: :view do
  before(:each) do
    assign(:articles, [
      Article.create!(
        title: "Title",
        slug: "Slug",
        body: "MyText",
        description: "MyDescr",
        published: false
      ),
      Article.create!(
        title: "Title",
        slug: "Slug",
        body: "MyText",
        description: "MyDescr",
        published: false
      )
    ])
  end

  it "renders a list of articles" do
    render
    assert_select "tr>td", text: "Title".to_s, count: 2
    assert_select "tr>td", text: "Slug".to_s, count: 2
    assert_select "tr>td", text: "MyDescr".to_s, count: 2
    assert_select "tr>td", text: false.to_s, count: 2
  end
end
