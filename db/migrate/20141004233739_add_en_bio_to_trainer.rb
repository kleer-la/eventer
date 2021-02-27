class AddEnBioToTrainer < ActiveRecord::Migration[5.0]
  def up
    add_column :trainers, :bio_en, :text
  end

  def down
    remove_column :trainers, :bio_en
  end
end
