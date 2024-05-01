# frozen_string_literal: true

FactoryBot.define do
  factory :service do
    name              { 'Default Service Name' }
    subtitle          { 'Default subtitle for the service.' }
    value_proposition { 'Default value_proposition' }
    outcomes          { '<ul><li>one</li></ul>' }
    program           { '<ol><ul><li>one</li></ul></ol>' }
    target            { 'Default target' }
    side_image        { 'https://exampe.com/side.png' }
    service_area
  end
end
