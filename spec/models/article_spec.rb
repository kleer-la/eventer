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

  context "abstract" do
    it "body w/o double empty line or </p>" do
      @article.body = 'some text'
      expect(@article.abstract).to eq 'some text'
    end
    it "body until double empty line " do
      @article.body = 'some text\n\nAnother text'
      expect(@article.abstract).to eq 'some text'
    end
    it "body until </p>" do
      @article.body = '<p>some text</p>Another text'
      expect(@article.abstract).to eq '<p>some text</p>'
    end
    it "body until </p> before \n\n" do
      @article.body = '<p>some text</p>Another \n\n text'
      expect(@article.abstract).to eq '<p>some text</p>'
    end
    it "body w/o </p> or \n\n and more than 500 chars" do
      @article.body = '0123456789ABCDEF' * 32
      expect(@article.abstract.length).to eq 500
    end

  end
end
