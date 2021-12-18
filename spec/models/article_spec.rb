require 'rails_helper'

RSpec.describe Article, type: :model do
  before(:each) do
    @article = FactoryBot.build(:article)
  end

  it "create a valid instance" do
    expect(@article.valid?).to be true
  end

  it "title, body, description are required" do
     @article.title= ""
     @article.body= ""
     @article.description= ""
    expect(@article.valid?).to be false
    expect(@article.errors.count).to be 3
  end

  it "Slug is calculated w/empty" do
     @article.title= "Dolor sit amet"
     @article.slug= ''
     @article.save!
    expect(@article.slug).to eq 'dolor-sit-amet'
  end

  it "Slug is calculated w/nil" do
     @article.title= "Dolor sit amet"
     @article.slug= nil
     @article.save!
    expect(@article.slug).to eq 'dolor-sit-amet'
  end
  it "add HABM author (trainer)" do
    article= FactoryBot.create(:article)
    trainer= FactoryBot.create(:trainer)
    article.trainers << trainer
    expect(article.trainers.count).to be 1
    expect(trainer.articles.count).to be 1
  end

end
