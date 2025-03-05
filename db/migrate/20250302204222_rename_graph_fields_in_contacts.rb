class RenameGraphFieldsInContacts < ActiveRecord::Migration[7.1]
  def change
    rename_column :contacts, :graph_file_path, :assessment_report_url
    rename_column :contacts, :graph_generated_at, :assessment_report_generated_at
  end
end
