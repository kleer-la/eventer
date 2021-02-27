class EventCustomPricesEmailTextChangedToText < ActiveRecord::Migration[5.0]
  def change
  	change_column :events, :custom_prices_email_text, :text
  end
end
