class AddResourceToAssessments < ActiveRecord::Migration[7.1]
  def change
    add_reference :assessments, :resource, null: true, foreign_key: true
  end
end
