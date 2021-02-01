class CreateParticipants < ActiveRecord::Migration
  def change
    create_table :participants do |t|
      t.string :fname
      t.string :lname
      t.string :email
      t.string :phone
      t.references :event

      t.timestamps null: true
    end
    add_index :participants, :event_id
  end
end
