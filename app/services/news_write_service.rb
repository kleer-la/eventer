# frozen_string_literal: true

class NewsWriteService < ContentWriteService
  self.model = News
  self.editable_fields = %i[title description lang url img video audio event_date where]
  self.long_fields = %w[description]
  # Unlike Article, News carries no separate publishing permission: whoever may
  # edit it in the admin may publish it.
  self.guarded_publication = false
end
