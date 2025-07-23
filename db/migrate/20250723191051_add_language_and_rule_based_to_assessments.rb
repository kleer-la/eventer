class AddLanguageAndRuleBasedToAssessments < ActiveRecord::Migration[7.2]
  def change
    add_column :assessments, :language, :string, default: 'es', null: false
    add_column :assessments, :rule_based, :boolean, default: false, null: false
  end
end
