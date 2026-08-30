# frozen_string_literal: true

class UpdateNewsTool < AuthenticatedTool
  tool_name 'update_news'
  requires_permission :update, News

  description <<~MD
    Edits a news item by id. Only the fields you pass are touched.

    Two steps: confirm=false (the default) previews the change without saving.
  MD

  arguments do
    required(:id).filled(:integer).description('Numeric id of the news item')
    optional(:title).filled(:string).description('Headline')
    optional(:description).filled(:string).description('Body of the announcement')
    optional(:lang).filled(:string).description("Language: 'es' or 'en'")
    optional(:url).filled(:string).description('Link the item points at')
    optional(:event_date).filled(:string).description('Date of the event, YYYY-MM-DD')
    optional(:where).filled(:string).description('Where it happens')
    optional(:img).filled(:string).description('Image URL')
    optional(:video).filled(:string).description('Video URL')
    optional(:audio).filled(:string).description('Audio URL')
    optional(:visible).filled(:bool).description('Show or hide it on the site')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(id:, confirm: false, visible: nil, **fields)
    item = News.find(id)
    NewsWriteService.new(ability: ability, record: item, published: visible, **fields)
                    .call(confirm: confirm).to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No news item with id #{id}"] }.to_json
  end
end
