FactoryBot.define do
  factory :mail_template do
    trigger_type { :contact_form }
    identifier { 'welcome_email' }
    subject { 'Welcome to our service' }
    content { 'Hello {{name}}, thank you for contacting us.' }
    delivery_schedule { :immediate }
    to { 'support@example.com' }
    cc { nil }
    active { true }
  end
end
