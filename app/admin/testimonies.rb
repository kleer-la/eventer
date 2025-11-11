# frozen_string_literal: true

ActiveAdmin.register Testimony do
  menu parent: 'Services Mgnt'

  permit_params :first_name, :last_name, :profile_url, :photo_url, :service_id, :stared, :testimony,
                :testimonial_type, :testimonial_id

  controller do
    def scoped_collection
      super.includes(:testimonial)
    end
  end

  filter :first_name
  filter :last_name
  filter :stared
  filter :testimonial_type, as: :select, collection: %w[EventType Service]
  filter :testimonial_id
  filter :created_at

  index do
    selectable_column
    id_column
    column :first_name
    column :last_name
    column :profile_url
    column :photo_url
    column :testimonial_type
    column('Related To') do |testimony|
      if testimony.testimonial.present?
        link_to testimony.testimonial.try(:name) || testimony.testimonial.try(:title),
                [:admin, testimony.testimonial]
      end
    end
    column :stared
    actions
  end

  show do
    attributes_table do
      row :first_name
      row :last_name
      row :profile_url
      row :photo_url do |testimony|
        image_tag testimony.photo_url if testimony.photo_url.present?
      end
      row :testimonial_type
      row('Related To') do |testimony|
        if testimony.testimonial.present?
          link_to testimony.testimonial.try(:name) || testimony.testimonial.try(:title),
                  [:admin, testimony.testimonial]
        end
      end
      row :stared
      row :testimony do |testimony|
        raw testimony.testimony.body.to_s
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :first_name
      f.input :last_name
      f.input :profile_url, as: :url
      f.input :photo_url, as: :url

      # Polymorphic association selector
      f.input :testimonial_type, as: :select, collection: %w[EventType Service],
              include_blank: false

      # Show both EventType and Service options, grouped
      # User should select testimonial_type first to know which to pick
      if f.object.new_record?
        # New record - show combined list with groups
        f.input :testimonial_id, as: :select,
                collection: [
                  ['Event Types', EventType.order(:name).map { |et| [et.name, et.id, { 'data-type': 'EventType' }] }],
                  ['Services', Service.order(:name).map { |s| [s.name, s.id, { 'data-type': 'Service' }] }]
                ],
                label: 'Related To',
                include_blank: 'Select testimonial type first',
                hint: 'First select EventType or Service above, then choose from the list'
      elsif f.object.testimonial_type == 'EventType'
        # Editing EventType testimony
        f.input :testimonial_id, as: :select,
                collection: EventType.order(:name).map { |et| [et.name, et.id] },
                label: 'Related To (Event Type)',
                include_blank: false
      else
        # Editing Service testimony
        f.input :testimonial_id, as: :select,
                collection: Service.order(:name).map { |s| [s.name, s.id] },
                label: 'Related To (Service)',
                include_blank: false
      end

      f.input :stared, label: 'Featured (publicly visible)'
      f.input :testimony, as: :rich_text_area
    end
    f.actions
  end
end
