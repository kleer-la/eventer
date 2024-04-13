# frozen_string_literal: true

FactoryBot.define do
  factory :service_area do
    name            { 'Default Service Area Name' }
    summary         { 'summary' }
    cta_message     { 'cta_message' }
    icon            {'https://exampe.com/icon.png' }
    slogan          { 'slogan' }
    subtitle        { 'subtitle' }
    description     { 'description' }
    side_image      {'https://exampe.com/side.png' }
    target          { 'target' }
    primary_color   { '#FF0080' }
    secondary_color { '#FF8080' }
  end
end
