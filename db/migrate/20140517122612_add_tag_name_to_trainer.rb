class AddTagNameToTrainer < ActiveRecord::Migration
  def change
  	add_column :trainers, :tag_name, :string
  end
end
