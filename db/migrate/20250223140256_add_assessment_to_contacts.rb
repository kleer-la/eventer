class AddAssessmentToContacts < ActiveRecord::Migration[7.1]
  def change
    add_reference :contacts, :assessment, null: true, foreign_key: true
    add_column :contacts, :graph_file_path, :string
    add_column :contacts, :graph_generated_at, :datetime
  end
end
