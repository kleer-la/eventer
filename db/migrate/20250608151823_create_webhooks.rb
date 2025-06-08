class CreateWebhooks < ActiveRecord::Migration[7.2]
  def change
    create_table :webhooks do |t|
      t.string :url
      t.string :event
      t.string :secret
      t.boolean :active

      t.timestamps
    end
  end
end
