class AddCustomPricesEmailTextToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :custom_prices_email_text, :string
  end
end
