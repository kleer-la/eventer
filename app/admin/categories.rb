# frozen_string_literal: true

ActiveAdmin.register Category do
  menu label: 'Categorías', parent: 'Others', priority: 91

  actions :index, :show, :edit, :update, :new, :create, :destroy

  permit_params :name, :name_en, :codename, :description, :description_en, :tagline, :tagline_en, :visible, :order

  filter :codename_cont, label: 'Código'
  filter :name_or_name_en_or_tagline_or_tagline_en_or_description_or_description_en_cont,
         label: 'Cualquier el texto (ambos idiomas)'
  filter :visible, label: 'Visible'

  index do
    selectable_column
    column 'Nombre', :name
    column 'Código', :codename
    toggle_bool_column 'Visible', :visible
    column 'Orden', :order
    column 'Descripción', :description
    actions
  end

  show do |category|
    panel 'Información de la configuración' do
      attributes_table_for category do
        row('Código', &:codename)
        row('Visible', &:visible)
        row('Orden', &:order)
      end
    end
    panel 'Español' do
      attributes_table_for category do
        row('Nombre', &:name)
        row('Subtítulo', &:tagline)
        markdown_row('Descripción', &:description)
      end
    end
    panel 'Inglés' do
      attributes_table_for category do
        row('Nombre', &:name_en)
        row('Subtítulo', &:tagline_en)
        markdown_row('Descripción', &:description_en)
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs 'Información de la categoría' do
      f.input :codename, label: 'Código'
      f.input :visible, label: 'Visible'
      f.input :order, label: 'Orden'
    end
    f.inputs 'Español' do
      f.input :name, label: 'Nombre'
      f.input :tagline, label: 'Subtítulo'
      f.input :description, label: 'Descripción',
                            hint: "Este texto soporta #{link_to('Markdown', 'https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet', target: '_blank')} y HTML.".html_safe
    end
    f.inputs 'Inglés' do
      f.input :name_en, label: 'Nombre'
      f.input :tagline_en, label: 'Subtítulo'
      f.input :description_en, label: 'Descripción',
                               hint: "Este texto soporta #{link_to('Markdown', 'https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet', target: '_blank')} y HTML.".html_safe
    end
    f.actions
  end
end
