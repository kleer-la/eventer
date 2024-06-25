class AddIllustratorToResources < ActiveRecord::Migration[7.1]
  def change
    create_table :illustrations do |t|
      t.references :resource, null: false, foreign_key: true
      t.references :trainer, null: false, foreign_key: true
      t.timestamps
    end
  end
end
