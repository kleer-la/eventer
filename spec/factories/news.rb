# frozen_string_literal: true

FactoryBot.define do
  factory :news do
    lang { 'es' }
    title { 'Breaking News: Agile Training Revolution' }
    where { 'Buenos Aires, Argentina' }
    description { 'This is an exciting development in the world of agile training and coaching.' }
    url { 'https://example.com/news/agile-training-revolution' }
    img { 'https://example.com/images/news-image.jpg' }
    event_date { 1.week.from_now.to_date }
    visible { true }

    trait :english do
      lang { 'en' }
      title { 'Breaking News: Agile Training Revolution' }
      where { 'Buenos Aires, Argentina' }
      description { 'This is an exciting development in the world of agile training and coaching.' }
    end

    trait :spanish do
      lang { 'es' }
      title { 'Últimas Noticias: Revolución en Entrenamiento Ágil' }
      where { 'Buenos Aires, Argentina' }
      description { 'Este es un desarrollo emocionante en el mundo del entrenamiento y coaching ágil.' }
    end

    trait :with_media do
      video { 'https://youtube.com/watch?v=example' }
      audio { 'https://podcast.example.com/episode-1' }
    end

    trait :with_trainers do
      after(:create) do |news|
        news.trainers << create(:trainer)
        news.trainers << create(:trainer2)
      end
    end

    trait :past_event do
      event_date { 2.weeks.ago.to_date }
    end

    trait :future_event do
      event_date { 1.month.from_now.to_date }
    end

    trait :hidden do
      visible { false }
    end
  end
end