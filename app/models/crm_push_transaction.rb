class CrmPushTransaction < ActiveRecord::Base
	has_many :items, :foreign_key => 'crm_push_transaction_id', :class_name => "CrmPushTransactionItem"
	belongs_to :event
	belongs_to :user

	def start!(mailer= EventMailer)
		self.event.participants.each do |participant|
			crm_push_item = CrmPushTransactionItem.create(:crm_push_transaction => self, :participant => participant)
			crm_push_item.push!
		end
		mailer.delay.alert_event_crm_push_finished(self)
	end
end
