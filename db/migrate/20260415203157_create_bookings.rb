class CreateBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :bookings do |t|
      t.references :trainer, null: false, foreign_key: true
      t.references :service_area, foreign_key: true
      t.string :visitor_name, null: false
      t.string :visitor_email, null: false
      t.string :visitor_company
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :google_event_id
      t.string :status, default: 'confirmed'
      t.text :notes
      t.json :qualifying_answers
      t.timestamps
    end
  end
end
