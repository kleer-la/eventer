class AddLongBioToTrainers < ActiveRecord::Migration[7.1]
  def change
    add_column :trainers, :long_bio, :text
    add_column :trainers, :long_bio_en, :text
  end
end
