# frozen_string_literal: true

class CreatePodcasts < ActiveRecord::Migration[7.1]
  def change
    create_table :podcasts do |t|
      t.string :title
      t.string :youtube_url
      t.string :spotify_url
      t.string :thumbnail_url

      t.timestamps
    end
  end
end
