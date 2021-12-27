# frozen_string_literal: true

class EventCustomPricesEmailTextChangedToText < ActiveRecord::Migration[4.2]
  def change
    change_column :events, :custom_prices_email_text, :text
  end
end
