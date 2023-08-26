ActiveAdmin.register EventType do
  filter :kleer_cert_seal_image_present, as: :boolean #, label: 'Cert Image is Empty'
  filter :kleer_cert_seal_image_blank, as: :boolean #, label: 'Cert Image is Not Empty'
  filter :kleer_cert_seal_image

  EventType.attribute_names.each do |attribute|
    filter attribute.to_sym
  end

  index do
    column :name
    column :lang
    column :duration
    column :deleted
    column :noindex
    actions defaults: false do |event_type|
      link_to 'Edit', edit_event_type_path(event_type)
    end
  end
end
