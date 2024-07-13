# frozen_string_literal: true

ActiveAdmin.register Event do
  menu priority: 2

  Event.attribute_names.each do |attribute|
    filter attribute.to_sym
  end

  index do
    column :date
    column 'Tipo evento', :event_type do |event|
      event.event_type&.name
    end
    column 'Detalles', :event_type do |event|
      "#{event.country.iso_code.downcase} #{event.city}"
    end
    column :draft
    column :cancelled
    column :is_sold_out
    actions defaults: false do |event|
      link_to 'Edit', edit_event_path(event)
    end
  end
end
