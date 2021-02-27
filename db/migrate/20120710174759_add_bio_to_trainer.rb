class AddBioToTrainer < ActiveRecord::Migration[5.0]
  def up
		add_column :trainers, :bio, :text
  end

	def down
		remove_column :trainers, :bio
	end
end
