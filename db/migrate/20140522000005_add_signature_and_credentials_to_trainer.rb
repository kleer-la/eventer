# frozen_string_literal: true

class AddSignatureAndCredentialsToTrainer < ActiveRecord::Migration[4.2]
  def change
    add_column :trainers, :signature_image, :string
    add_column :trainers, :signature_credentials, :string
  end
end
