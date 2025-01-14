FactoryBot.define do
  factory :contact do
    trigger_type { :contact_form }
    email { 'user@example.com' }
    form_data { { 
      name: 'John Doe', 
      message: 'Hello', lang: 'es',
      resource_slug: 'default-resource',
      can_we_contact: '0',
      suscribe: 'false'
    } }

    status { :pending }

    trait :with_english do
      form_data { { name: 'John Doe', message: 'Hello', lang: 'en' } }
    end

    trait :with_spanish do
      form_data { { name: 'John Doe', message: 'Hello', lang: 'es' } }
    end
  end
end
