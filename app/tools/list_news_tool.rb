# frozen_string_literal: true

class ListNewsTool < AuthenticatedTool
  tool_name 'list_news'
  requires_permission :read, News

  DEFAULT_LIMIT = 25
  MAX_LIMIT = 100

  description <<~MD
    Lists news items — the short announcements with a date, a place and a link.
    Newest event date first. News says "visible" rather than published, and
    unlike articles it carries no separate publishing permission.
  MD

  arguments do
    optional(:query).filled(:string).description('Substring matched against the title')
    optional(:lang).filled(:string).description("Language: 'es' or 'en'")
    optional(:visible).filled(:bool).description('true = only visible, false = only hidden')
    optional(:limit).filled(:integer).description("How many to return (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
  end

  def call(query: nil, lang: nil, visible: nil, limit: DEFAULT_LIMIT)
    scope = News.order(event_date: :desc, created_at: :desc)
    scope = scope.where('title LIKE ?', "%#{query}%") if query.present?
    scope = scope.where(lang: lang) if lang.present?
    scope = scope.where(visible: visible) unless visible.nil?

    items = scope.limit(limit.clamp(1, MAX_LIMIT))
    { count: items.size, news: items.map { |item| summary(item) } }.to_json
  end

  private

  def summary(item)
    { id: item.id, title: item.title, lang: item.lang, visible: item.visible,
      event_date: item.event_date, where: item.where, url: item.url }
  end
end
