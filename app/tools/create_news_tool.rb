# frozen_string_literal: true

class CreateNewsTool < AuthenticatedTool
  tool_name 'create_news'
  requires_permission :create, News

  description <<~MD
    Creates a news item. It is created hidden unless you pass visible=true.

    Two steps: confirm=false (the default) previews without saving; call again
    with confirm=true once the user agrees.
  MD

  arguments do
    required(:title).filled(:string).description('Headline')
    optional(:description).filled(:string).description('Body of the announcement')
    optional(:lang).filled(:string).description("Language: 'es' or 'en' (defaults to es)")
    optional(:url).filled(:string).description('Link the item points at')
    optional(:event_date).filled(:string).description('Date of the event, YYYY-MM-DD')
    optional(:where).filled(:string).description('Where it happens')
    optional(:img).filled(:string).description('Image URL')
    optional(:video).filled(:string).description('Video URL')
    optional(:audio).filled(:string).description('Audio URL')
    optional(:visible).filled(:bool).description('true = show it on the site')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(confirm: false, visible: false, **fields)
    NewsWriteService.new(ability: ability, published: visible, **fields).call(confirm: confirm).to_json
  end
end
