class AddSignatureAndCredentialsToTrainer < ActiveRecord::Migration
  def change
  	add_column :trainers, :signature_image, :string
  	add_column :trainers, :signature_credentials, :string
  end
end
