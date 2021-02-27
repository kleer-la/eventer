class AddConditionsToEvent < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :specific_conditions, :text
  end
end
