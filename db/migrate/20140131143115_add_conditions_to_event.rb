class AddConditionsToEvent < ActiveRecord::Migration
  def change
    add_column :events, :specific_conditions, :text
  end
end
