# frozen_string_literal: true

class CreateCrmPushTransactionItems < ActiveRecord::Migration[4.2]
  def change
    create_table :crm_push_transaction_items do |t|
      t.references :crm_push_transaction
      t.references :participant
      t.text :log
      t.string :result

      t.timestamps null: true
    end
  end
end
