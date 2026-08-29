# frozen_string_literal: true

class GetArticleTool < AuthenticatedTool
  tool_name 'get_article'
  requires_permission :read, Article

  description <<~MD
    Returns one blog article in full, body included, looked up by slug or by id.
    Use it before editing, so the change is made against the current text.
  MD

  arguments do
    required(:id).filled(:string).description('Article slug (preferred) or numeric id')
  end

  def call(id:)
    article = Article.friendly.find(id)
    {
      id: article.id, slug: article.slug, title: article.title, tabtitle: article.tabtitle,
      lang: article.lang, published: article.published, selected: article.selected,
      noindex: article.noindex, industry: article.industry, category: article.category_name,
      description: article.description, cover: article.cover, header: article.header,
      body: article.body, trainers: article.trainers.map(&:name),
      substantive_change_at: article.substantive_change_at, updated_at: article.updated_at
    }.to_json
  rescue ActiveRecord::RecordNotFound
    { error: 'not_found', error_description: "No article with slug or id #{id.inspect}" }.to_json
  end
end
