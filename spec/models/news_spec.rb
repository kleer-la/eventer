# frozen_string_literal: true

require 'rails_helper'

RSpec.describe News, type: :model do
  describe 'factory' do
    it 'creates a valid news item' do
      news = build(:news)
      expect(news).to be_valid
    end
  end

  describe 'attributes' do
    let(:news) { build(:news) }

    it 'has required attributes' do
      expect(news).to respond_to(:lang)
      expect(news).to respond_to(:title)
      expect(news).to respond_to(:where)
      expect(news).to respond_to(:description)
      expect(news).to respond_to(:url)
      expect(news).to respond_to(:img)
      expect(news).to respond_to(:video)
      expect(news).to respond_to(:audio)
      expect(news).to respond_to(:event_date)
      expect(news).to respond_to(:visible)
    end

    it 'stores attributes correctly' do
      news.title = 'Test News Title'
      news.where = 'Test Location'
      news.description = 'Test description'
      news.url = 'https://test.com'

      expect(news.title).to eq('Test News Title')
      expect(news.where).to eq('Test Location')
      expect(news.description).to eq('Test description')
      expect(news.url).to eq('https://test.com')
    end
  end

  describe 'language enum' do
    it 'defines language enum correctly' do
      expect(News.langs).to eq({ 'es' => 0, 'en' => 1 })
    end

    it 'allows setting language as string' do
      news = build(:news, lang: 'es')
      expect(news.lang).to eq('es')
      expect(news.es?).to be true
      expect(news.en?).to be false
    end

    it 'allows setting language as integer' do
      news = build(:news, lang: 1)
      expect(news.lang).to eq('en')
      expect(news.en?).to be true
      expect(news.es?).to be false
    end

    it 'provides language query methods' do
      spanish_news = create(:news, :spanish)
      english_news = create(:news, :english)

      expect(spanish_news.es?).to be true
      expect(spanish_news.en?).to be false
      expect(english_news.en?).to be true
      expect(english_news.es?).to be false
    end

    it 'can filter by language' do
      spanish_news = create(:news, :spanish)
      english_news = create(:news, :english)

      spanish_items = News.where(lang: 'es')
      english_items = News.where(lang: 'en')

      expect(spanish_items).to include(spanish_news)
      expect(spanish_items).not_to include(english_news)
      expect(english_items).to include(english_news)
      expect(english_items).not_to include(spanish_news)
    end
  end

  describe 'associations' do
    it 'has and belongs to many trainers' do
      news = create(:news)
      trainer1 = create(:trainer)
      trainer2 = create(:trainer2)

      news.trainers << trainer1
      news.trainers << trainer2

      expect(news.trainers).to include(trainer1, trainer2)
      expect(trainer1.news).to include(news)
      expect(trainer2.news).to include(news)
    end

    it 'works with factory trait for trainers' do
      news = create(:news, :with_trainers)

      expect(news.trainers.count).to eq(2)
      expect(news.trainers.first).to be_a(Trainer)
    end

    it 'can remove trainers' do
      news = create(:news, :with_trainers)
      initial_count = news.trainers.count
      trainer_to_remove = news.trainers.first

      news.trainers.delete(trainer_to_remove)

      expect(news.trainers.count).to eq(initial_count - 1)
      expect(news.trainers).not_to include(trainer_to_remove)
    end
  end

  describe 'ImageReference behavior' do
    let(:image_url) { 'https://kleer-images.s3.sa-east-1.amazonaws.com/test-image.jpg' }
    let(:video_url) { 'https://youtube.com/embed/test-video' }
    let(:audio_url) { 'https://podcast.example.com/episode.mp3' }

    describe '#image_references' do
      let(:news) do
        create(:news, 
               img: image_url,
               video: video_url, 
               audio: audio_url,
               description: "Check out this image: #{image_url} embedded in text")
      end

      it 'finds direct references in img field' do
        references = news.image_references(image_url)
        expect(references).to include(
          hash_including(
            field: :img,
            type: 'direct'
          )
        )
      end

      it 'finds direct references in video field' do
        references = news.image_references(video_url)
        expect(references).to include(
          hash_including(
            field: :video,
            type: 'direct'
          )
        )
      end

      it 'finds direct references in audio field' do
        references = news.image_references(audio_url)
        expect(references).to include(
          hash_including(
            field: :audio,
            type: 'direct'
          )
        )
      end

      it 'finds embedded references in description text field' do
        references = news.image_references(image_url)
        embedded_ref = references.find { |ref| ref[:type] == 'embedded' }
        expect(embedded_ref).to include(
          field: :description,
          type: 'embedded'
        )
      end

      it 'returns empty array when URL not found' do
        references = news.image_references('https://not-found.com/missing.jpg')
        expect(references).to be_empty
      end
    end
  end

  describe 'media fields' do
    it 'stores video URLs' do
      news = create(:news, video: 'https://youtube.com/watch?v=example')
      expect(news.video).to eq('https://youtube.com/watch?v=example')
    end

    it 'stores audio URLs' do
      news = create(:news, audio: 'https://podcast.example.com/episode-1')
      expect(news.audio).to eq('https://podcast.example.com/episode-1')
    end

    it 'works with media trait' do
      news = create(:news, :with_media)

      expect(news.video).to be_present
      expect(news.audio).to be_present
      expect(news.video).to include('youtube.com')
      expect(news.audio).to include('podcast.example.com')
    end
  end

  describe 'event date handling' do
    it 'stores event dates correctly' do
      event_date = 1.week.from_now.to_date
      news = create(:news, event_date: event_date)

      expect(news.event_date).to eq(event_date)
    end

    it 'can filter by date ranges' do
      past_news = create(:news, :past_event)
      future_news = create(:news, :future_event)

      past_items = News.where('event_date < ?', Date.current)
      future_items = News.where('event_date > ?', Date.current)

      expect(past_items).to include(past_news)
      expect(past_items).not_to include(future_news)
      expect(future_items).to include(future_news)
      expect(future_items).not_to include(past_news)
    end
  end

  describe 'visibility' do
    it 'defaults to visible' do
      news = build(:news)
      expect(news.visible).to be true
    end

    it 'can be set to hidden' do
      news = build(:news, :hidden)
      expect(news.visible).to be false
    end

    describe 'scopes' do
      before do
        @visible_news = create(:news, visible: true)
        @hidden_news = create(:news, :hidden)
      end

      it 'visible scope returns only visible news' do
        visible_items = News.visible
        expect(visible_items).to include(@visible_news)
        expect(visible_items).not_to include(@hidden_news)
      end

      it 'hidden scope returns only hidden news' do
        hidden_items = News.hidden
        expect(hidden_items).to include(@hidden_news)
        expect(hidden_items).not_to include(@visible_news)
      end
    end
  end

  describe 'Ransack functionality' do
    it 'returns expected searchable attributes' do
      expected_attributes = %w[audio created_at description event_date id id_value img lang
                               title updated_at url video visible where]

      expect(News.ransackable_attributes).to match_array(expected_attributes)
    end

    it 'can search by title using Ransack' do
      agile_news = create(:news, title: 'Agile Training Workshop')
      scrum_news = create(:news, title: 'Scrum Master Certification')

      # Simulate Ransack search
      agile_results = News.where('title LIKE ?', '%Agile%')
      scrum_results = News.where('title LIKE ?', '%Scrum%')

      expect(agile_results).to include(agile_news)
      expect(agile_results).not_to include(scrum_news)
      expect(scrum_results).to include(scrum_news)
      expect(scrum_results).not_to include(agile_news)
    end
  end

  describe 'data queries and scopes' do
    before do
      @spanish_news = create(:news, :spanish, title: 'Noticias en Español')
      @english_news = create(:news, :english, title: 'English News')
      @news_with_video = create(:news, video: 'https://youtube.com/example')
      @news_without_video = create(:news, video: nil)
    end

    it 'can filter by language' do
      spanish_items = News.es
      english_items = News.en

      expect(spanish_items).to include(@spanish_news)
      expect(spanish_items).not_to include(@english_news)
      expect(english_items).to include(@english_news)
      expect(english_items).not_to include(@spanish_news)
    end

    it 'can filter by presence of media' do
      with_video = News.where.not(video: [nil, ''])
      without_video = News.where(video: [nil, ''])

      expect(with_video).to include(@news_with_video)
      expect(with_video).not_to include(@news_without_video)
      expect(without_video).to include(@news_without_video)
    end

    it 'can order by event date' do
      old_news = create(:news, event_date: 1.month.ago, title: 'Old News')
      recent_news = create(:news, event_date: 1.day.ago, title: 'Recent News')
      future_news = create(:news, event_date: 1.week.from_now, title: 'Future News')

      # Query only these three specific news items
      test_news_ids = [old_news.id, recent_news.id, future_news.id]
      chronological = News.where(id: test_news_ids).order(:event_date)
      reverse_chronological = News.where(id: test_news_ids).order(event_date: :desc)

      expect(chronological.first).to eq(old_news)
      expect(chronological.last).to eq(future_news)
      expect(reverse_chronological.first).to eq(future_news)
      expect(reverse_chronological.last).to eq(old_news)
    end
  end
end
