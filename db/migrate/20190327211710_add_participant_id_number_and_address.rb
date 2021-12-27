# frozen_string_literal: true

class AddParticipantIdNumberAndAddress < ActiveRecord::Migration[4.2]
  def change
    add_column :participants, :id_number, :string
    add_column :participants, :address, :string
  end
end
