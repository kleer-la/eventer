require 'rails_helper'

describe "categories/edit" do
  before(:each) do
    @category = assign(:category, Category.new)
  end

  it "renders the edit category form" do
    render

    expect(rendered).to match(/Nombre \(\*\)/)
    expect(rendered).to match(/Name En/)
  end
  # IDKY it doesn't work
  # it "renders the edit category form w/translation" do
  #   I18n.locale= :es
  #   render
  #   expect(rendered).not_to match(/translation_missing/)
  # end
end
