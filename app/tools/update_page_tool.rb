# frozen_string_literal: true

class UpdatePageTool < AuthenticatedTool
  tool_name 'update_page'
  requires_permission :update, Page

  description <<~MD
    Edits a page by id. Only the fields you pass are touched. Sections are not
    editable here — use the admin for those.

    Two steps: confirm=false (the default) previews without saving.
  MD

  arguments do
    required(:id).filled(:integer).description('Numeric id of the page')
    optional(:name).filled(:string).description('Page name')
    optional(:lang).filled(:string).description("Language: 'es' or 'en'")
    optional(:slug).filled(:string).description('URL slug, unique within the language')
    optional(:template).filled(:string).description('overlay | flagship')
    optional(:cover).filled(:string).description('Cover image URL')
    optional(:canonical).filled(:string).description('Canonical URL, if it points elsewhere')
    optional(:seo_title).filled(:string).description('SEO title')
    optional(:seo_description).filled(:string).description('SEO description')
    optional(:show_in_footer).filled(:bool).description('true = link it from the footer')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(id:, confirm: false, **fields)
    page = Page.find(id)
    PageWriteService.new(ability: ability, record: page, **fields).call(confirm: confirm).to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No page with id #{id}"] }.to_json
  end
end
