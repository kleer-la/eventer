class CreateRecommendedContents < ActiveRecord::Migration[7.1]
  def change
    create_table :recommended_contents do |t|
      t.references :source, polymorphic: true, null: false
      t.references :target, polymorphic: true, null: false
      t.integer :relevance_order, default: 50, null: false

      t.timestamps
    end
  end
end
