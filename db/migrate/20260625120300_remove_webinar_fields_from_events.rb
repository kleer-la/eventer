# frozen_string_literal: true

# Removes the legacy webinar-management fields from events (#75). There is no
# Webinar model/table; these are dead columns from the old Hangout/Twitter
# webinar viewer (unreachable: routeless view, no mailer/job/notification).
# Modern online delivery (mode='ol', time_zone_name, online_course_codename)
# is unrelated and kept.
class RemoveWebinarFieldsFromEvents < ActiveRecord::Migration[8.1]
  def up
    remove_column :events, :notify_webinar_start if column_exists?(:events, :notify_webinar_start)
    remove_column :events, :webinar_started if column_exists?(:events, :webinar_started)
    remove_column :events, :embedded_player if column_exists?(:events, :embedded_player)
    remove_column :events, :twitter_embedded_search if column_exists?(:events, :twitter_embedded_search)
  end

  def down
    add_column :events, :notify_webinar_start, :boolean, default: false
    add_column :events, :webinar_started, :boolean, default: false
    add_column :events, :embedded_player, :text
    add_column :events, :twitter_embedded_search, :text
  end
end
