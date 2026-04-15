class AddGoogleOauthToTrainers < ActiveRecord::Migration[7.2]
  def change
    add_column :trainers, :google_uid, :string
    add_column :trainers, :google_access_token, :text
    add_column :trainers, :google_refresh_token, :text
    add_column :trainers, :google_token_expires_at, :datetime
    add_column :trainers, :google_calendar_connected, :boolean, default: false
    add_column :trainers, :booking_enabled, :boolean, default: false
  end
end
