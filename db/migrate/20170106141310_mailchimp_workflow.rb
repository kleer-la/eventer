class MailchimpWorkflow < ActiveRecord::Migration
  def up
		add_column :events, :mailchimp_workflow, :boolean
		add_column :events, :mailchimp_workflow_call, :string
	end
	
	def down
		remove_column :events, :mailchimp_workflow
		remove_column :events, :mailchimp_workflow_call
	end
end
