class AddShouldAskForRefererCodeToEvent < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :should_ask_for_referer_code, :boolean, default: false
  end
end
