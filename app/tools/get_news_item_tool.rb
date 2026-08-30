# frozen_string_literal: true

class GetNewsItemTool < AuthenticatedTool
  tool_name 'get_news_item'
  requires_permission :read, News

  description 'Returns one news item in full, by id. News items have no slug.'

  arguments do
    required(:id).filled(:integer).description('Numeric id of the news item')
  end

  def call(id:)
    item = News.find(id)
    { id: item.id, title: item.title, description: item.description, lang: item.lang,
      visible: item.visible, event_date: item.event_date, where: item.where, url: item.url,
      img: item.img, video: item.video, audio: item.audio,
      trainers: item.trainers.map(&:name), updated_at: item.updated_at }.to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No news item with id #{id}"] }.to_json
  end
end
