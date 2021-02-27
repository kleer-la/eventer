class MailchimpWarmupWorkflow < ActiveRecord::Migration[5.0]
  def up
    add_column :events, :mailchimp_workflow_for_warmup, :boolean
    add_column :events, :mailchimp_workflow_for_warmup_call, :string
  end

  def down
    remove_column :events, :mailchimp_workflow_for_warmup
    remove_column :events, :mailchimp_workflow_for_warmup_call
  end
end
