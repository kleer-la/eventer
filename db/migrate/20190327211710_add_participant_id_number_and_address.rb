class AddParticipantIdNumberAndAddress < ActiveRecord::Migration
  def change
    add_column :participants, :id_number, :string
    add_column :participants, :address, :string
  end


end
