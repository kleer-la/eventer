# frozen_string_literal: true

class AddOrderingToServices < ActiveRecord::Migration[7.1]
  def change
    add_column :services, :ordering, :integer
  end
end
