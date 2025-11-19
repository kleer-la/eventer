# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { 'user@test.com' }
    password { 'please' }
    password_confirmation { 'please' }
  end

  factory :admin_role, class: Role do
    name { :administrator }
  end

  factory :comercial_role, class: Role do
    name { :comercial }
  end

  factory :marketing_role, class: Role do
    name { :marketing }
  end

  factory :content_role, class: Role do
    name { :content }
  end

  factory :publisher_role, class: Role do
    name { :publisher }
  end

  factory :administrator, class: User do
    email { 'admin@user.com' }
    password { 'please' }
    password_confirmation { 'please' }
    roles { [FactoryBot.create(:admin_role)] }
  end

  factory :comercial, class: User do
    email { 'comercial@user.com' }
    password { 'please' }
    password_confirmation { 'please' }
    roles { [FactoryBot.create(:comercial_role)] }
  end

  factory :marketing_user, class: User do
    email { 'marketing@user.com' }
    password { 'please' }
    password_confirmation { 'please' }
    roles { [FactoryBot.create(:marketing_role)] }
  end

  factory :content_user, class: User do
    email { 'content@user.com' }
    password { 'please' }
    password_confirmation { 'please' }
    roles { [FactoryBot.create(:content_role)] }
  end

  factory :publisher_user, class: User do
    email { 'publisher@user.com' }
    password { 'please' }
    password_confirmation { 'please' }
    roles { [FactoryBot.create(:publisher_role)] }
  end
  factory :admin_user, class: User do
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    roles { [FactoryBot.create(:admin_role)] }
  end

  # # spec/factories/events.rb
  # FactoryBot.define do
  #   factory :event do
  #     date { Date.tomorrow }
  #     association :event_type
  #   end
  # end

  # # spec/factories/participants.rb
  # FactoryBot.define do
  #   factory :participant do
  #     fname { Faker::Name.first_name }
  #     lname { Faker::Name.last_name }
  #     email { Faker::Internet.email }
  #     phone { Faker::PhoneNumber.phone_number }
  #     quantity { 1 }
  #     status { 'N' }
  #     association :event
  #   end
  # end
end
