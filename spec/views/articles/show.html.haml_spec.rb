require 'rails_helper'

RSpec.describe "articles/show", type: :view do
  before(:each) do
    @article = assign(:article, Article.create!(
      title: "Title",
      slug: "Slug",
      body: "MyText"
      description: "MyDescr"
      published: "false"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/Slug/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/MyDescr/)
    expect(rendered).to match(/MyText/)
  end
end
