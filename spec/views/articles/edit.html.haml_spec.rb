require 'rails_helper'

RSpec.describe "articles/edit", type: :view do
  before(:each) do
    @article = assign(:article, Article.create!(
      title: "MyString",
      slug: "MyString",
      body: "MyText",
      description: "MyText",
      published: false
    ))
  end

  it "renders the edit article form" do
    render

    assert_select "form[action=?][method=?]", article_path(@article), "post" do

      assert_select "input[name=?]", "article[title]"

      assert_select "input[name=?]", "article[slug]"

      assert_select "textarea[name=?]", "article[body]"
      assert_select "input[name=?]", "article[description]"
      assert_select "input[name=?]", "article[published]"
    end
  end
end
