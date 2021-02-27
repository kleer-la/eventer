class AddExtraScriptToEvent < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :extra_script, :text
  end
end
