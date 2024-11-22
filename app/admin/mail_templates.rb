# app/admin/mail_templates.rb
ActiveAdmin.register MailTemplate do
  menu parent: 'Mail'
  permit_params :trigger_type, :identifier, :subject, :content, :delivery_schedule, :to, :cc, :active

  index do
    selectable_column
    id_column
    column :trigger_type
    column :identifier
    column :subject
    column :to
    column :delivery_schedule
    column :active
    column :updated_at
    actions
  end

  filter :trigger_type
  filter :identifier
  filter :subject
  filter :active
  filter :delivery_schedule
  filter :created_at

  form do |f|
    f.inputs do
      f.input :trigger_type
      f.input :identifier, hint: "Unique identifier for this template (e.g., 'contact_confirmation')"
      f.input :subject
      f.input :content, as: :text,
                        hint: 'Available variables: {{name}}, {{email}}, {{message}}, {{page}}, {{resource_slug}}. {{resource_getit_en}}, {{resource_getit_es}}, {{resource_title_en}}, {{resource_title_es}}'
      f.input :delivery_schedule
      f.input :to
      f.input :cc
      f.input :active
    end
    f.actions
  end

  show do
    attributes_table do
      row :trigger_type
      row :identifier
      row :subject
      row :content do |template|
        content_tag :pre, template.content
      end
      row :delivery_schedule
      row :to
      row :cc
      row :active
      row :created_at
      row :updated_at
    end
  end

  action_item :preview, only: :show do
    link_to 'Preview Template', preview_admin_mail_template_path(mail_template)
  end

  member_action :preview, method: %i[get post] do
    @template = resource
    @page_title = "Preview: #{@template.identifier}"
    @sample_data = params[:sample_data] || {
      name: 'John Doe',
      email: 'test@example.com',
      message: 'This is a test message',
      context: '/es/servicios'
    }

    if request.post?
      @sample_data = JSON.parse(params[:custom_data])
      @preview_content = @template.render_content(
        Contact.new(form_data: @sample_data)
      )
    end
  end
end
