# frozen_string_literal: true

class CreateArticleTool < AuthenticatedTool
  tool_name 'create_article'
  requires_permission :create, Article

  description <<~MD
    Creates a blog article. It is created unpublished unless you pass
    published=true, which needs publishing rights.

    Two steps: confirm=false (the default) validates and returns a preview
    without saving; call again with confirm=true once the user agrees.

    The slug is derived from the title when you do not pass one.
  MD

  arguments do
    required(:title).filled(:string).description('Article title')
    required(:description).filled(:string).description('Summary used for SEO, at most 160 characters')
    required(:body).filled(:string).description('Full body')
    optional(:tabtitle).filled(:string).description('Browser tab / SEO title')
    optional(:lang).filled(:string).description("Language: 'es' or 'en' (defaults to es)")
    optional(:slug).filled(:string).description('URL slug; derived from the title when omitted')
    optional(:category).filled(:string).description('Category name')
    optional(:cover).filled(:string).description('Cover image URL')
    optional(:header).filled(:string).description('Header image URL')
    optional(:industry).filled(:string)
                       .description('finantial | technology | public_services | consumer_goods | energy')
    optional(:noindex).filled(:bool).description('true = ask search engines not to index it')
    optional(:published).filled(:bool).description('Publish on creation. Needs publishing rights')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(confirm: false, **fields)
    ArticleWriteService.new(ability: ability, **fields).call(confirm: confirm).to_json
  end
end
