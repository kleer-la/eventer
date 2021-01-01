require 'rails_helper'

describe "categories/new" do
    before(:each) do
      @category = assign(:category, Category.new)
    end
  
    it "renders the edit category form" do
      render
  
      expect(rendered).to match(/Nombre \(\*\)/)
      expect(rendered).to match(/Name En/)
    end
end