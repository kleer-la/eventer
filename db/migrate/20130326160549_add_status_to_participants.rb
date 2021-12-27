# frozen_string_literal: true

class AddStatusToParticipants < ActiveRecord::Migration[4.2]
  def up
    add_column :participants, :status, :string
  end

  def down
    remove_column :participants, :status
  end
end
