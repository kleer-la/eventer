ActiveAdmin.register Coupon do
  menu priority: 5

  permit_params :coupon_type, :code, :internal_name, :icon, :expires_on, :display, :active, 
                :percent_off, :amount_off, event_type_ids: []

  index do
    selectable_column
    id_column
    column :coupon_type do |coupon|
      coupon.coupon_type.humanize
    end
    column :code
    column :internal_name
    column :icon
    column :expires_on
    column :display
    column :active
    column :percent_off
    column :amount_off
    actions
  end

  filter :coupon_type
  filter :code
  filter :internal_name
  filter :expires_on
  filter :display
  filter :active

  form do |f|
    f.inputs do
      f.input :coupon_type, as: :select, collection: Coupon.coupon_types.keys.map { |key| [key.humanize, key] }
      # f.input :coupon_type, as: :select, collection: Coupon.coupon_types.keys.map(&:humanize)
      f.input :code
      f.input :internal_name
      f.input :icon
      f.input :expires_on, as: :datepicker
      f.input :display
      f.input :active
      f.input :percent_off
      f.input :amount_off

      f.input :event_types, as: :check_boxes, collection: EventType.included_in_catalog.order(:name).map { |et| 
        ["#{et.unique_name}(#{et.platform})", et.id] 
      }
    end
    f.actions
  end

  show do
    attributes_table do
      row :coupon_type do |coupon|
        coupon.coupon_type.humanize
      end
      row :code
      row :internal_name
      row :icon
      row :expires_on
      row :display
      row :active
      row :percent_off
      row :amount_off
      panel "Associated Event Types" do
        coupon.event_types.each do |event_type|
          div event_type.name # Replace :name with the attribute you want to display
        end
      end
    end
  end
end
