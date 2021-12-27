# frozen_string_literal: true

class AddRefererCodeToParticipant < ActiveRecord::Migration[4.2]
  def change
    add_column :participants, :referer_code, :string
  end
end
