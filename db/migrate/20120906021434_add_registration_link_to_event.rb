# frozen_string_literal: true

class AddRegistrationLinkToEvent < ActiveRecord::Migration[4.2]
  def up
    add_column :events, :registration_link, :string
  end

  def down
    remove_column :events, :registration_link
  end
end
