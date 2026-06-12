# frozen_string_literal: true

class AddAudioToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :audio, :string
  end
end
