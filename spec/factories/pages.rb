# frozen_string_literal: true

FactoryBot.define do
  factory :page do
    name { 'Default Page Name' }
    lang { :en }
  end
end
