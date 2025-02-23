class CreateAssessments < ActiveRecord::Migration[7.1]
  def change
    create_table :assessments do |t|
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
