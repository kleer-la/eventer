class CreateAuthorships < ActiveRecord::Migration[6.1]
  def change
    create_table :authorships do |t|
      t.references :resource, null: false, foreign_key: true
      t.references :trainer, null: false, foreign_key: true

      t.timestamps
    end
    add_index :authorships, %i[resource_id trainer_id], unique: true
  end
end
