# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Article, type: :model do
  before(:each) do
    @article = FactoryBot.build(:article)
  end

  it 'create a valid instance' do
    expect(@article.valid?).to be true
  end

  it 'title, body, description are required' do
    @article.title = ''
    @article.body = ''
    @article.description = ''
    expect(@article.valid?).to be false
    expect(@article.errors.count).to be 3
  end

  it 'Slug is calculated w/empty' do
    @article.title = 'Dolor sit amet'
    @article.slug = ''
    @article.save!
    expect(@article.slug).to eq 'dolor-sit-amet'
  end

  it 'Slug is calculated w/nil' do
    @article.title = 'Dolor sit amet'
    @article.slug = nil
    @article.save!
    expect(@article.slug).to eq 'dolor-sit-amet'
  end
  it 'add HABM author (trainer)' do
    article = FactoryBot.create(:article)
    trainer = FactoryBot.create(:trainer)
    article.trainers << trainer
    expect(article.trainers.count).to be 1
    expect(trainer.articles.count).to be 1
  end

  context 'abstract' do
    it 'body w/o double empty line or </p>' do
      @article.body = 'some text'
      expect(@article.abstract).to eq 'some text'
    end
    it 'body until double empty line ' do
      @article.body = "some text\r\n\r\nAnother text"
      expect(@article.abstract).to eq 'some text'
    end
    it 'body until </p>' do
      @article.body = '<p>some text</p>Another text'
      expect(@article.abstract).to eq '<p>some text</p>'
    end
    it "body until </p> before \n\n" do
      @article.body = "<p>some text</p>Another \r\n\r\n text"
      expect(@article.abstract).to eq '<p>some text</p>'
    end
    it "body w/o </p> or \n\n and more than 500 chars" do
      @article.body = '0123456789ABCDEF' * 32
      expect(@article.abstract.length).to eq 500
    end
  end

  describe '#recommended' do
    let(:article) { FactoryBot.create(:article) }
    let(:recommended_article) { FactoryBot.create(:article) }
    let(:recommended_event_type) { FactoryBot.create(:event_type) }

    before do
      FactoryBot.create(:recommended_content, source: article, target: recommended_article, relevance_order: 2)
      FactoryBot.create(:recommended_content, source: article, target: recommended_event_type, relevance_order: 1)
    end

    it 'returns recommended items in the correct order with proper formatting' do
      recommended = article.recommended

      expect(recommended.size).to eq(2)
      expect(recommended.first['type']).to eq('event_type')
      expect(recommended.last['type']).to eq('article')

      expect(recommended.first['id']).to eq(recommended_event_type.id)
      expect(recommended.first['title']).to eq(recommended_event_type.name)

      expect(recommended.last['id']).to eq(recommended_article.id)
      expect(recommended.last['title']).to eq(recommended_article.title)
    end
  end
end
