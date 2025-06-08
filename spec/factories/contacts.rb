FactoryBot.define do
  factory :contact do
    trigger_type { :contact_form }
    email { 'user@example.com' }
    form_data do
      {
        name: 'John Doe',
        message: 'Hello', lang: 'es',
        resource_slug: 'default-resource',
        content_updates_opt_in: '0',
        newsletter_opt_in: 'false'
      }
    end

    status { :pending }

    trait :with_newsletter_opt_in do
      form_data do
        {
          name: 'John Doe',
          message: 'Hello',
          lang: 'es',
          resource_slug: 'default-resource',
          content_updates_opt_in: '0',
          newsletter_opt_in: 'true'
        }
      end
    end

    trait :without_newsletter_opt_in do
      form_data do
        {
          name: 'John Doe',
          message: 'Hello',
          lang: 'es',
          resource_slug: 'default-resource',
          content_updates_opt_in: '0',
          newsletter_opt_in: 'false'
        }
      end
    end

    trait :with_english do
      form_data { { name: 'John Doe', message: 'Hello', lang: 'en' } }
    end

    trait :with_spanish do
      form_data { { name: 'John Doe', message: 'Hello', lang: 'es' } }
    end
  end
end
