# frozen_string_literal: true

class AddTestimonyToParticipant < ActiveRecord::Migration[4.2]
  def change
    add_column :participants, :testimony, :text
  end
end
