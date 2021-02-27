class AddEnBioToTrainer < ActiveRecord::Migration
  def up
    add_column :trainers, :bio_en, :text
  end

  def down
    remove_column :trainers, :bio_en
  end
end
