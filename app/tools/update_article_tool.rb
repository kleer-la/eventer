# frozen_string_literal: true

class UpdateArticleTool < AuthenticatedTool
  tool_name 'update_article'
  requires_permission :update, Article

  description <<~MD
    Edits an existing blog article, looked up by slug or id. Only the fields you
    pass are touched; everything else is left alone.

    Two steps: confirm=false (the default) validates and returns a preview of
    what would change, saving nothing — show it to the user. Call again with
    confirm=true only once they explicitly agree.

    Read the article with get_article first, so the edit is made against the
    current text. Changing `published` needs publishing rights: a `content` user
    can edit but not publish, exactly as in the admin screens.
  MD

  arguments do
    required(:id).filled(:string).description('Article slug (preferred) or numeric id')
    optional(:title).filled(:string).description('Article title')
    optional(:tabtitle).filled(:string).description('Browser tab / SEO title')
    optional(:description).filled(:string).description('Summary used for SEO, at most 160 characters')
    optional(:body).filled(:string).description('Full body. Changing it regenerates the spoken audio')
    optional(:lang).filled(:string).description("Language: 'es' or 'en'")
    optional(:slug).filled(:string).description('URL slug. Changing it keeps the old one redirecting')
    optional(:category).filled(:string).description('Category name')
    optional(:cover).filled(:string).description('Cover image URL')
    optional(:header).filled(:string).description('Header image URL')
    optional(:industry).filled(:string)
                       .description('finantial | technology | public_services | consumer_goods | energy')
    optional(:noindex).filled(:bool).description('true = ask search engines not to index it')
    optional(:selected).filled(:bool).description('true = feature it on the blog')
    optional(:published).filled(:bool).description('Publish or unpublish. Needs publishing rights')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(id:, confirm: false, **fields)
    article = Article.friendly.find(id)
    ArticleWriteService.new(ability: ability, record: article, **fields).call(confirm: confirm).to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No article with slug or id #{id.inspect}"] }.to_json
  end
end
