# frozen_string_literal: true

class NewsWriteService < ContentWriteService
  self.model = News
  self.editable_fields = %i[title description lang url img video audio event_date where]
  self.long_fields = %w[description]
  # News says "visible", and unlike Article it carries no separate publishing
  # permission: whoever may edit it in the admin may show or hide it.
  self.publication_flag = :visible
  self.guarded_publication = false
end
