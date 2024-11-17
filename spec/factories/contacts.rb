FactoryBot.define do
  factory :contact do
    trigger_type { :contact_form }
    email { 'user@example.com' }
    form_data { { name: 'John Doe', message: 'Hello' } }
    status { :pending }
  end
end
