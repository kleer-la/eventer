class AddExtraScriptToEvent < ActiveRecord::Migration
  def change
    add_column :events, :extra_script, :text
  end
end
