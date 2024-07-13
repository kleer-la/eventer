# frozen_string_literal: true

class AddPhotoLinkedinToParticipants < ActiveRecord::Migration[5.2]
  def change
    add_column :participants, :profile_url, :string, null: true
    add_column :participants, :photo_url, :string, null: true
  end
end
