class AddCompanyNameToParticipants < ActiveRecord::Migration[6.0]
  def change
    add_column :participants, :company_name, :string
  end
end
