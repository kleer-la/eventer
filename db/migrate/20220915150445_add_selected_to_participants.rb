# frozen_string_literal: true

class AddSelectedToParticipants < ActiveRecord::Migration[5.2]
  def change
    add_column :participants, :selected, :boolean, null: false, default: false
  end
end
