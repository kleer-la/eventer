require 'rails_helper'

describe "categories/show" do
    before(:each) do
        @category = assign(:category, 
            FactoryBot.create(:category, :name => "Name 1", :codename => 'code1', :description => "Text 1")
        )
    end

    it "renders the show category form" do
        render

        expect(rendered).to match(/Name 1/)
        expect(rendered).to match(/code1/)
        expect(rendered).to match(/Text 1/)
    end
end
