ActiveAdmin.register EventType do
  filter :name, filters: [:contains, :starts_with, :ends_with, :equals]
  ActiveAdmin.register EventType do
    filter :name, filters: [:contains, :starts_with, :ends_with, :equals]

    EventType.attribute_names.each do |attribute|
      filter attribute.to_sym, filters: [:contains, :starts_with, :ends_with, :equals]
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
  
end
