# frozen_string_literal: true

class PodcastWriteService < ContentWriteService
  self.model = Podcast
  self.editable_fields = %i[title description spotify_url youtube_url thumbnail_url]
  self.rich_text_fields = %i[description]
  # A podcast is visible as soon as it exists; there is no flag to guard.
  self.publication_flag = nil
end
