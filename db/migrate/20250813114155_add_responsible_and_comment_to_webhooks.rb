class AddResponsibleAndCommentToWebhooks < ActiveRecord::Migration[7.2]
  def change
    add_column :webhooks, :responsible_id, :integer
    add_column :webhooks, :comment, :text
    add_index :webhooks, :responsible_id
    add_foreign_key :webhooks, :trainers, column: :responsible_id
  end
end
