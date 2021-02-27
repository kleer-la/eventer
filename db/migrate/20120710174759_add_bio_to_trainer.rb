class AddBioToTrainer < ActiveRecord::Migration
  def up
		add_column :trainers, :bio, :text
  end

	def down
		remove_column :trainers, :bio
	end
end
