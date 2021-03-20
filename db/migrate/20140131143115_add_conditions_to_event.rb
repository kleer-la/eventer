class AddConditionsToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :specific_conditions, :text
  end
end
