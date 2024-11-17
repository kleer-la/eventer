class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.integer :trigger_type, null: false
      t.string :email, null: false
      if ActiveRecord::Base.connection.adapter_name.downcase.to_sym == :postgresql
        t.jsonb :form_data, null: false, default: {}
      else
        t.json :form_data, null: false, default: {}
      end
      t.integer :status, default: 0
      t.datetime :processed_at

      t.timestamps
    end
  end
end
