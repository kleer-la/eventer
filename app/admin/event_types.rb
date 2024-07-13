# frozen_string_literal: true

ActiveAdmin.register EventType do
  menu priority: 3
  filter :kleer_cert_seal_image_present, as: :boolean # , label: 'Cert Image is Empty'
  filter :kleer_cert_seal_image_blank, as: :boolean # , label: 'Cert Image is Not Empty'
  filter :kleer_cert_seal_image

  scope :all, default: false
  scope 'Catalog', :included_in_catalog, default: true

  EventType.attribute_names.each do |attribute|
    filter attribute.to_sym
  end

  config.sort_order = 'name_asc'
  index do
    column :name
    column :lang
    column :duration
    column :behavior do |event_type|
      if event_type.behavior.include?('canonical')
        link_to event_type.behavior, edit_admin_event_type_path(event_type.canonical)
      elsif event_type.behavior == 'redirect to url'
        link_to event_type.behavior, event_type.external_site_url, target: '_blank'
      else
        event_type.behavior
      end
    end
    actions defaults: false do |event_type|
      link_to 'Edit', edit_event_type_path(event_type)
    end
  end
end
