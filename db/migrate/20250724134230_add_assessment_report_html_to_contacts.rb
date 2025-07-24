class AddAssessmentReportHtmlToContacts < ActiveRecord::Migration[7.2]
  def change
    add_column :contacts, :assessment_report_html, :text
  end
end
