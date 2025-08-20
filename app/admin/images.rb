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
          f.input :convert_to_webp, as: :boolean, 
                  label: 'Convert to WebP (for PNG/JPEG/JPG files)',
                  input_html: { id: 'convert_to_webp', checked: true }
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
          function cleanFilename(filename) {
            // Split filename and extension
            var lastDotIndex = filename.lastIndexOf('.');
            var basename = lastDotIndex !== -1 ? filename.slice(0, lastDotIndex) : filename;
            var extension = lastDotIndex !== -1 ? filename.slice(lastDotIndex) : '';
        #{'    '}
            // Clean the basename
            var cleaned = basename
              .normalize('NFD')                     // Normalize unicode characters
              .replace(/[\u0300-\u036f]/g, '')     // Remove diacritics
              .toLowerCase()                        // Convert to lowercase
              .replace(/[^a-z0-9]+/g, '-')         // Replace special chars with hyphen
              .replace(/^-+|-+$/g, '')             // Remove leading/trailing hyphens
              .replace(/-+/g, '-');                // Replace multiple hyphens with single hyphen
        #{'    '}
            // Return cleaned name with lowercase extension
            return cleaned + extension.toLowerCase();
          }

          function toggleWebpOption(filename) {
            var extension = filename.split('.').pop().toLowerCase();
            var webpOption = $('#convert_to_webp').closest('.input');
            
            if (['png', 'jpg', 'jpeg'].includes(extension)) {
              webpOption.show();
            } else {
              webpOption.hide();
              $('#convert_to_webp').prop('checked', false);
            }
          }

          $('#image_file').change(function() {
            var fileName = $(this).val().split('\\\\').pop();
            var cleanedFilename = cleanFilename(fileName);
            $('#image_path').val(cleanedFilename);
            toggleWebpOption(fileName);
          });

          // Hide WebP option by default
          $('#convert_to_webp').closest('.input').hide();
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
      table_for grouped_images.keys.sort do |_base_key|
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

              item "Copy #{File.extname(image.key)}",
                   admin_images_copy_path(bucket: image_bucket, key: image.key),
                   method: :post,
                   confirm: 'This will create a copy with a cleaned filename. Continue?'
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
    convert_to_webp = params[:image][:convert_to_webp] == '1'

    begin
      # Upload original image
      @public_url = store.upload(file.tempfile, img_name, @image_bucket)
      uploaded_files = [img_name]
      
      # Convert and upload WebP version if requested and supported
      if convert_to_webp && ImageConversionService.supported_for_webp?(img_name)
        begin
          # Convert to WebP
          webp_path = ImageConversionService.convert_to_webp(file.tempfile.path)
          webp_filename = ImageConversionService.webp_filename(img_name)
          
          # Upload WebP file
          webp_file = File.open(webp_path, 'rb')
          store.upload(webp_file, webp_filename, @image_bucket)
          uploaded_files << webp_filename
          
          # Clean up temporary WebP file
          webp_file.close
          File.delete(webp_path) if File.exist?(webp_path)
        rescue StandardError => e
          Rails.logger.warn "WebP conversion failed for #{img_name}: #{e.message}"
          # Continue with original upload even if WebP conversion fails
        end
      end

      if uploaded_files.size > 1
        flash[:notice] = "Images successfully uploaded: #{uploaded_files.join(', ')}"
      else
        flash[:notice] = 'Image successfully uploaded'
      end
      
      redirect_to admin_images_show_path(bucket: @image_bucket, key: img_name)
    rescue StandardError => e
      flash[:error] = "Error uploading image: #{e.message}"
      redirect_to admin_images_path
    end
  end

  page_action :show, method: :get do
    @image_bucket = params[:bucket] || session[:image_bucket] || 'image'
    @image_key = params[:key]

    # store = FileStoreService.current
    @image_url = FileStoreService.image_url(@image_key, @image_bucket)

    render 'show', layout: 'active_admin'
  end

  page_action :delete, method: :delete do
    @image_bucket = params[:bucket] || session[:image_bucket] || 'image'
    @image_key = params[:key]
    @image_url = FileStoreService.image_url(@image_key, @image_bucket)

    # Check if image is in use (try both URL formats)
    usage = ImageUsageService.find_usage(@image_url)
    @image_url_with_spaces = @image_url&.gsub('+', ' ')
    usage.merge!(ImageUsageService.find_usage(@image_url_with_spaces)) if @image_url_with_spaces != @image_url

    if usage.any?
      flash[:error] = 'Cannot delete image as it is in use. Please remove all references first.'
      redirect_to admin_images_usage_path(bucket: @image_bucket, key: @image_key)
      return
    end

    store = FileStoreService.current
    begin
      store.delete(@image_key, @image_bucket)
      flash[:notice] = 'Image successfully deleted'
    rescue StandardError => e
      flash[:error] = "Error deleting image: #{e.message}"
    end

    redirect_to admin_images_path
  end

  page_action :usage, method: :get do
    @image_bucket = params[:bucket] || session[:image_bucket] || 'image'
    @image_key = params[:key]

    @image_url = FileStoreService.image_url(@image_key, @image_bucket)

    # Also try with spaces instead of plus signs for the usage search
    # since database might store URLs with spaces while admin interface uses plus signs
    @image_url_with_spaces = @image_url&.gsub('+', ' ')

    @usage = ImageUsageService.find_usage(@image_url)
    @usage.merge!(ImageUsageService.find_usage(@image_url_with_spaces)) if @image_url_with_spaces != @image_url

    render 'usage'
  end

  page_action :copy, method: :post do
    @image_bucket = params[:bucket] || session[:image_bucket] || 'image'
    @image_key = params[:key]

    store = FileStoreService.current

    begin
      # Generate cleaned filename
      original_name = File.basename(@image_key, '.*')
      extension = File.extname(@image_key)

      # Clean the filename by removing/replacing problematic characters
      cleaned_name = original_name
                     .gsub(/[áàâäãåā]/, 'a')
                     .gsub(/[éèêë]/, 'e')
                     .gsub(/[íìîï]/, 'i')
                     .gsub(/[óòôöõø]/, 'o')
                     .gsub(/[úùûü]/, 'u')
                     .gsub(/ñ/, 'n')
                     .gsub(/ç/, 'c')
                     .gsub(/[ÁÀÂÄÃÅĀ]/, 'A')
                     .gsub(/[ÉÈÊË]/, 'E')
                     .gsub(/[ÍÌÎÏ]/, 'I')
                     .gsub(/[ÓÒÔÖÕØ]/, 'O')
                     .gsub(/[ÚÙÛÜ]/, 'U')
                     .gsub(/Ñ/, 'N')
                     .gsub(/Ç/, 'C')
                     .gsub(/\s+/, '-') # Replace spaces with hyphens
                     .gsub(/[^a-zA-Z0-9._-]/, '') # Remove other special characters
                     .gsub(/-+/, '-')         # Replace multiple hyphens with single
                     .gsub(/^-|-$/, '')       # Remove leading/trailing hyphens

      new_key = "#{cleaned_name}#{extension}"

      # Check if target already exists
      if store.exists?(new_key, @image_bucket)
        # Add timestamp to make it unique
        timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
        base_name = File.basename(cleaned_name, '.*')
        new_key = "#{base_name}_#{timestamp}#{extension}"
      end

      # Copy the image
      success = store.copy(@image_key, new_key, @image_bucket)

      if success
        flash[:notice] = "Image copied successfully as '#{new_key}'. Original: '#{@image_key}'"
        flash[:alert] = "⚠️ Remember to update any references to use the new filename: #{new_key}"
      else
        flash[:error] = 'Failed to copy image'
      end
    rescue StandardError => e
      flash[:error] = "Error copying image: #{e.message}"
    end

    redirect_to admin_images_path(bucket: @image_bucket)
  end
end
