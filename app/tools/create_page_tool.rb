# frozen_string_literal: true

class CreatePageTool < AuthenticatedTool
  tool_name 'create_page'
  requires_permission :create, Page

  description <<~MD
    Creates a page. Name and language are required; the slug is derived from the
    name when omitted and only has to be unique within that language.

    The page is created without sections — those are added in the admin. A
    'flagship' page with no sections renders empty, and the preview says so.

    Two steps: confirm=false (the default) previews without saving.
  MD

  arguments do
    required(:name).filled(:string).description('Page name')
    required(:lang).filled(:string).description("Language: 'es' or 'en'")
    optional(:slug).filled(:string).description('URL slug, unique within the language')
    optional(:template).filled(:string).description('overlay (default) | flagship')
    optional(:cover).filled(:string).description('Cover image URL')
    optional(:canonical).filled(:string).description('Canonical URL, if it points elsewhere')
    optional(:seo_title).filled(:string).description('SEO title')
    optional(:seo_description).filled(:string).description('SEO description')
    optional(:show_in_footer).filled(:bool).description('true = link it from the footer')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(confirm: false, **fields)
    PageWriteService.new(ability: ability, **fields).call(confirm: confirm).to_json
  end
end
