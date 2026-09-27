# frozen_string_literal: true

class EpisodeWriteService < ContentWriteService
  self.model = Episode
  self.editable_fields = %i[title description season episode released_at
                            spotify_url youtube_url thumbnail_url]
  self.rich_text_fields = %i[description]

  private

  def model_warnings
    return [] unless @record.podcast && duplicate_number?

    ["Season #{@record.season} episode #{@record.episode} already exists in this podcast."]
  end

  def duplicate_number?
    @record.podcast.episodes
           .where(season: @record.season, episode: @record.episode)
           .where.not(id: @record.id)
           .exists?
  end
end
