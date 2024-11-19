# spec/factories/mail_templates.rb
FactoryBot.define do
  factory :mail_template do
    trigger_type { :contact_form }
    sequence(:identifier) { |n| "template_#{n}" }
    subject { 'Test Subject' }
    content { 'Hello {{name}}, thank you for contacting us.' }
    delivery_schedule { :immediate }
    to { 'test@example.com' }
    cc { nil }
    active { true }

    trait :for_downloads do
      trigger_type { 'download_form' }
      sequence(:identifier) { |n| "download_template_#{n}" }
    end

    trait :for_contacts do
      trigger_type { 'contact_form' }
      sequence(:identifier) { |n| "contact_template_#{n}" }
    end
  end
end
