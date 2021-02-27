class EventCustomPricesEmailTextChangedToText < ActiveRecord::Migration
  def change
  	change_column :events, :custom_prices_email_text, :text
  end
end
