# frozen_string_literal: true

require 'mini_magick'

class ImageConversionService
  class << self
    def convert_to_webp(source_file_path, quality: 80)
      # Validate that the source file exists
      raise ArgumentError, 'Source file does not exist' unless File.exist?(source_file_path)

      # Get original file extension to determine if conversion is needed
      original_extension = File.extname(source_file_path).downcase
      unless ['.png', '.jpg', '.jpeg'].include?(original_extension)
        raise ArgumentError, 'Unsupported file format for WebP conversion'
      end

      # Create temporary file for WebP output
      temp_webp_file = Tempfile.new(['converted', '.webp'])
      temp_webp_path = temp_webp_file.path
      temp_webp_file.close

      begin
        # Use MiniMagick to convert to WebP
        image = MiniMagick::Image.open(source_file_path)
        image.format 'webp'
        image.quality quality.to_s
        image.write temp_webp_path

        # Return the path to the converted file
        temp_webp_path
      rescue StandardError => e
        # Clean up temp file on error
        File.delete(temp_webp_path) if File.exist?(temp_webp_path)
        raise "WebP conversion failed: #{e.message}"
      end
    end

    def webp_filename(original_filename)
      # Replace the extension with .webp
      File.basename(original_filename, File.extname(original_filename)) + '.webp'
    end

    def supported_for_webp?(filename)
      extension = File.extname(filename).downcase
      ['.png', '.jpg', '.jpeg'].include?(extension)
    end
  end
end