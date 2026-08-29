# frozen_string_literal: true

class ListArticlesTool < AuthenticatedTool
  tool_name 'list_articles'
  requires_permission :read, Article

  DEFAULT_LIMIT = 25
  MAX_LIMIT = 100

  description <<~MD
    Lists blog articles with a summary of each one — id, slug, title, language,
    whether it is published, category and when it last changed substantively.
    Bodies are not included: use get_article for the full text of one article.

    Without filters it returns the most recently changed articles first.
  MD

  arguments do
    optional(:query).filled(:string).description('Substring matched against the title')
    optional(:lang).filled(:string).description("Language: 'es' or 'en'")
    optional(:published).filled(:bool).description('true = only published, false = only drafts')
    optional(:category).filled(:string).description('Category name')
    optional(:limit).filled(:integer).description("How many to return (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
  end

  def call(query: nil, lang: nil, published: nil, category: nil, limit: DEFAULT_LIMIT)
    scope = Article.includes(:category).order(substantive_change_at: :desc, created_at: :desc)
    scope = scope.where('title LIKE ?', "%#{query}%") if query.present?
    scope = scope.where(lang: lang) if lang.present?
    scope = scope.where(published: published) unless published.nil?
    scope = scope.joins(:category).where(categories: { name: category }) if category.present?

    articles = scope.limit(limit.clamp(1, MAX_LIMIT))
    { count: articles.size, articles: articles.map { |article| summary(article) } }.to_json
  end

  private

  def summary(article)
    { id: article.id, slug: article.slug, title: article.title, lang: article.lang,
      published: article.published, selected: article.selected, category: article.category_name,
      description: article.description, substantive_change_at: article.substantive_change_at }
  end
end
