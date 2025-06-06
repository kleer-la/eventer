class CreateShortUrls < ActiveRecord::Migration[7.2]
  def change
    create_table :short_urls do |t|
      t.string :short_code, null: false
      t.text :original_url, null: false
      t.integer :click_count, default: 0, null: false

      t.timestamps
    end
    add_index :short_urls, :short_code, unique: true
  end
end
