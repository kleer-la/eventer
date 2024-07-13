# frozen_string_literal: true

class AddPricingToService < ActiveRecord::Migration[7.1]
  def change
    add_column :services, :pricing, :string
  end
end
