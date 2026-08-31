# frozen_string_literal: true

# An episode has two publication states that were sharing one word: when it came
# out on Spotify or YouTube, and whether we show it on our own site. The date
# keeps its meaning under a name that says which one it is; the new flag is the
# site one, and matches what Article, News and the rest call `published`.
#
# Existing episodes are all on the site today, so they are backfilled as
# published; new ones start as drafts, like every other content type.
class AddPublishedToEpisodes < ActiveRecord::Migration[8.1]
  def up
    rename_column :episodes, :published_at, :released_at
    add_column :episodes, :published, :boolean, default: false, null: false
    execute 'UPDATE episodes SET published = TRUE'
  end

  def down
    remove_column :episodes, :published
    rename_column :episodes, :released_at, :published_at
  end
end
