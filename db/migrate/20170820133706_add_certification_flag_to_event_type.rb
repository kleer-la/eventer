class AddCertificationFlagToEventType < ActiveRecord::Migration
  def change
    add_column :event_types, :is_kleer_certification, :boolean, default: false
    add_column :event_types, :kleer_cert_seal_image, :string
  end
end
