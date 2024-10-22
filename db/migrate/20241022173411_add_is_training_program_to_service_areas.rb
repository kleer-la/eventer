class AddIsTrainingProgramToServiceAreas < ActiveRecord::Migration[7.1]
  def change
    add_column :service_areas, :is_training_program, :boolean, null: false, default: false
  end
end
