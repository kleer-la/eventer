# frozen_string_literal: true

class AddLinkedInUrlToTrainer < ActiveRecord::Migration[4.2]
  def up
    add_column :trainers, :linkedin_url, :string
  end

  def down
    remove_column :trainers, :linkedin_url
  end
end
