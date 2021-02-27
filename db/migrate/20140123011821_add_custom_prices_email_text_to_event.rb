class AddCustomPricesEmailTextToEvent < ActiveRecord::Migration
  def change
    add_column :events, :custom_prices_email_text, :string
  end
end
