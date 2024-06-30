class CreateEpisodes < ActiveRecord::Migration[7.1]
  def change
    create_table :episodes do |t|
      t.references :podcast, foreign_key: true
      t.integer :season
      t.integer :episode
      t.string :title
      t.string :youtube_url
      t.string :spotify_url
      t.string :thumbnail_url
      t.date :published_at

      t.timestamps
    end
  end
end
