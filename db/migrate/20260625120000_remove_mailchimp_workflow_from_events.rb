# frozen_string_literal: true

# Removes the dead Mailchimp automatic-mail-workflow fields from events (#76).
# The feature has no mailer/job/service code; these are orphaned columns.
class RemoveMailchimpWorkflowFromEvents < ActiveRecord::Migration[8.1]
  def up
    remove_column :events, :mailchimp_workflow if column_exists?(:events, :mailchimp_workflow)
    remove_column :events, :mailchimp_workflow_call if column_exists?(:events, :mailchimp_workflow_call)
    remove_column :events, :mailchimp_workflow_for_warmup if column_exists?(:events, :mailchimp_workflow_for_warmup)
    if column_exists?(:events, :mailchimp_workflow_for_warmup_call)
      remove_column :events, :mailchimp_workflow_for_warmup_call
    end
  end

  def down
    add_column :events, :mailchimp_workflow, :boolean
    add_column :events, :mailchimp_workflow_call, :string
    add_column :events, :mailchimp_workflow_for_warmup, :boolean
    add_column :events, :mailchimp_workflow_for_warmup_call, :string
  end
end
