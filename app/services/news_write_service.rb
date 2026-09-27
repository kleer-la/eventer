# frozen_string_literal: true

class NewsWriteService < ContentWriteService
  self.model = News
  self.editable_fields = %i[title description lang url img video audio event_date where]
  self.long_fields = %w[description]
end
