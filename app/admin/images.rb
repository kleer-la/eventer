def unique_extensions
  store = FileStoreService.current
  all_images = store.list('image') + store.list('certificate') + store.list('signature')
  all_images.map { |img| File.extname(img.key).delete('.').downcase }.uniq.sort
end

ActiveAdmin.register_page 'Images' do
  menu parent: 'Assets', priority: 10, label: 'Images'

  action_item :images do
    link_to 'Images', admin_images_path(bucket: 'image')
  end

  action_item :certificates do
    link_to 'Certificates', admin_images_path(bucket: 'certificate')
  end

  action_item :signatures do
    link_to 'Signatures', admin_images_path(bucket: 'signature')
  end
  action_item :view_old_version, only: :index do
    link_to 'Old version', '/images', class: 'button'
  end

  sidebar 'Filters', only: :index do
    active_admin_form_for 'filter', method: :get do |f|
      f.inputs do
        f.input :min_size,
                as: :number,
                label: 'Minimum Size (KB)',
                input_html: { value: params.dig(:filter, :min_size) }
        f.input :extension,
                as: :select,
                collection: unique_extensions,
                include_blank: 'All',
                selected: params.dig(:filter, :extension)
      end
      f.actions do
        f.action :submit, label: 'Filter'
        f.action :cancel, label: 'Clear Filters'
      end
    end
  end

  content title: 'Images' do
    image_bucket = params[:bucket] || session[:image_bucket] || 'image'
    session[:image_bucket] = image_bucket

    begin
      store = FileStoreService.current
      images = store.list(image_bucket)

      if params[:filter]
        if params[:filter][:min_size].present?
          min_size = params[:filter][:min_size].to_i * 1024 # Convert KB to bytes
          images = images.select { |img| img.size >= min_size }
        end

        if params[:filter][:extension].present?
          extension = params[:filter][:extension]
          images = images.select { |img| File.extname(img.key).delete('.').downcase == extension.downcase }
        end
      end
    rescue Aws::Errors::MissingCredentialsError
      flash.now[:error] = 'AWS credentials are missing. Please check your configuration.'
      images = []
    end

    panel "Upload #{image_bucket}" do
      active_admin_form_for :image, url: admin_images_upload_path, html: { multipart: true } do |f|
        f.inputs do
          f.input :file, as: :file, input_html: { id: 'image_file' }
          f.input :path, input_html: { placeholder: 'Image path', id: 'image_path' }
          f.input :image_bucket, input_html: { value: image_bucket }, as: :hidden
        end
        f.actions do
          f.action :submit, label: 'Upload Image'
        end
      end
    end
    script do
      raw <<~JS
        $(document).ready(function() {
          $('#image_file').change(function() {
            var fileName = $(this).val().split('\\\\').pop();
            $('#image_path').val(fileName);
          });
        });
      JS
    end

    if params[:filter].present?
      panel 'Active Filters' do
        ul do
          li "Minimum Size: #{params.dig(:filter, :min_size)} KB" if params.dig(:filter, :min_size).present?
          li "Extension: #{params.dig(:filter, :extension)}" if params.dig(:filter, :extension).present?
          li "Bucket: #{image_bucket}"
        end
      end
    end
    panel image_bucket do
      grouped_images = images.group_by { |image| File.basename(image.key, '.*') }
      table_for grouped_images.keys.sort do |base_key|
        column 'Name' do |base_key|
          base_key
        end

        column 'Extensions' do |base_key|
          grouped_images[base_key].map do |image|
            extension = File.extname(image.key).delete('.')
            link_to extension, admin_images_show_path(bucket: image_bucket, key: image.key), class: 'button'
          end.join(' ').html_safe
        end

        column 'Modified' do |base_key|
          grouped_images[base_key].map do |image|
            "#{File.extname(image.key).delete('.')}: #{image.last_modified.strftime('%Y-%m-%d %H:%M:%S')}"
          end.join('<br>').html_safe
        end

        column 'Size' do |base_key|
          grouped_images[base_key].map do |image|
            "#{File.extname(image.key).delete('.')}: #{number_to_human_size(image.size)}"
          end.join('<br>').html_safe
        end
        column 'Actions' do |base_key|
          dropdown_menu 'Actions' do
            grouped_images[base_key].each do |image|
              item "View #{File.extname(image.key)}",
                   admin_images_show_path(bucket: image_bucket, key: image.key)

              item "Usage #{File.extname(image.key)}",
                   admin_images_usage_path(bucket: image_bucket, key: image.key)
            end
          end
        end
      end
      para 'No images found.' unless images.present?
    end
  end

  page_action :upload, method: :post do
    if params[:image][:file].blank? || params[:image][:path].blank?
      flash[:error] = 'Missing information: image or path'
      redirect_to admin_images_path
      return
    end

    @image_bucket = params[:image][:image_bucket] || session[:image_bucket] || 'image'
    session[:image_bucket] = @image_bucket

    store = FileStoreService.current
    file = params[:image][:file]
    img_name = params[:image][:path]

    begin
      @public_url = store.upload(file.tempfile, img_name, @image_bucket)
      flash[:notice] = 'Image successfully uploaded'
    rescue StandardError => e
      flash[:error] = "Error uploading image: #{e.message}"
    end

    redirect_to admin_images_path
  end

  page_action :show, method: :get do
    @image_bucket = params[:bucket] || session[:image_bucket] || 'image'
    @image_key = params[:key]

    # store = FileStoreService.current
    @image_url = FileStoreService.image_url(@image_key, @image_bucket)

    render 'show', layout: 'active_admin'
  end

  page_action :usage, method: :get do
    @image_bucket = params[:bucket] || session[:image_bucket] || 'image'
    @image_key = params[:key]

    @image_url = FileStoreService.image_url(@image_key, @image_bucket)

    @usage = ImageUsageService.find_usage(@image_url)

    render 'usage'
  end
end
