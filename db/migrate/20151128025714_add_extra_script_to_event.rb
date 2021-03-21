class AddExtraScriptToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :extra_script, :text
  end
end
