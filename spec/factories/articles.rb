# frozen_string_literal: true

FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "Article Title #{n}" }
    sequence(:description) { |n| "Description for article #{n}" }
    body { 'This is the body of the article' }
    sequence(:slug) { |n| "article-slug-#{n}" }
  end
end
