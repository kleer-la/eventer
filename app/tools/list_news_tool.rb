# frozen_string_literal: true

class ListNewsTool < AuthenticatedTool
  tool_name 'list_news'
  requires_permission :read, News

  description <<~MD
    Lists news items — the short announcements with a date, a place and a link.
    Newest event date first. Unlike articles, news carries no separate
    publishing permission.
  MD

  arguments do
    optional(:query).filled(:string).description('Substring matched against the title')
    optional(:lang).filled(:string).description("Language: 'es' or 'en'")
    optional(:published).filled(:bool).description('true = only published, false = only unpublished')
    optional(:limit).filled(:integer).description("How many to return (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
  end

  def call(query: nil, lang: nil, published: nil, limit: DEFAULT_LIMIT)
    scope = News.order(event_date: :desc, created_at: :desc)
    scope = scope.where('title LIKE ?', "%#{query}%") if query.present?
    scope = scope.where(lang: lang) if lang.present?
    scope = scope.where(published: published) unless published.nil?

    items = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |item| summary(item) }
    listing(:news, items, total: scope.count, narrow: 'query, lang or published')
  end

  private

  def summary(item)
    { id: item.id, title: item.title, lang: item.lang, published: item.published,
      event_date: item.event_date, where: item.where, url: item.url }
  end
end
