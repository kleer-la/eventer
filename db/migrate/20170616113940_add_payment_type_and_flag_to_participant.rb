# frozen_string_literal: true

class AddPaymentTypeAndFlagToParticipant < ActiveRecord::Migration[4.2]
  def change
    add_column :participants, :is_payed, :boolean, default: false
    add_column :participants, :payment_type, :string
  end
end
