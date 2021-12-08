require 'rails_helper'

RSpec.describe Article, type: :model do
  before(:each) do
    @article = FactoryBot.build(:article)
  end

  it "create a valid instance" do
    expect(@article.valid?).to be true
  end

  it "title, body, description, slug are required" do
     @article.title= ""
     @article.body= ""
     @article.description= ""
     @article.slug= ""
    expect(@article.valid?).to be false    
    expect(@article.errors.count).to be 4
  end
end
