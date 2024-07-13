# frozen_string_literal: true

ActiveAdmin.register Testimony do
  menu parent: 'Services Mgnt'

  permit_params :first_name, :last_name, :profile_url, :photo_url, :service_id, :stared, :testimony

  index do
    selectable_column
    id_column
    column :first_name
    column :last_name
    column :profile_url
    column :photo_url
    column :service
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
      row :service
      row :stared
      row :testimony do |testimony|
        raw testimony.testimony.body.to_s
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :first_name
      f.input :last_name
      f.input :profile_url, as: :url
      f.input :photo_url, as: :url
      f.input :service
      f.input :stared
      f.input :testimony, as: :rich_text_area
    end
    f.actions
  end
end
