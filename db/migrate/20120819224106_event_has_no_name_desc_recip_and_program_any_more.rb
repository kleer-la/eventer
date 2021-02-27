class EventHasNoNameDescRecipAndProgramAnyMore < ActiveRecord::Migration
  def up
    remove_column :events, :name
    remove_column :events, :description
    remove_column :events, :recipients
    remove_column :events, :program
  end

	def down
		add_column :events, :name, :string
		add_column :events, :description, :text
		add_column :events, :recipients, :text
		add_column :events, :program, :text
	end
end
