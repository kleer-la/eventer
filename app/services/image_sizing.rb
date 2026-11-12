# frozen_string_literal: true

require 'mini_magick'

# How big a picture is, whether that slows its page down, and how to make it
# smaller before storing it (website17#465: a 2.7 MB PNG on the home page).
module ImageSizing
  RESIZABLE = %w[image/png image/jpeg image/webp].freeze
  # Past these a picture costs its page load time for no visible gain.
  HEAVY_BYTES = 300 * 1024
  WIDE_PIXELS = 1600

  module_function

  def dimensions(body, content_type)
    return {} if content_type == 'image/svg+xml'

    image = MiniMagick::Image.read(body)
    { width: image.width, height: image.height }
  rescue MiniMagick::Error, MiniMagick::Invalid
    {}
  end

  # A PNG, JPEG or WebP wider than max_width, scaled down and stripped of
  # metadata; anything else as it came.
  def shrink(body, content_type, max_width)
    return body unless max_width.to_i.positive? && RESIZABLE.include?(content_type)

    image = MiniMagick::Image.read(body)
    return body unless image.width > max_width.to_i

    image.resize("#{max_width.to_i}x")
    image.strip
    image.quality('80') unless content_type == 'image/png'
    image.to_blob
  end

  def warnings(bytes, width, content_type)
    return [] unless bytes > HEAVY_BYTES || width.to_i > WIDE_PIXELS

    ["It weighs #{bytes / 1024} KB and is #{width.to_i} px wide; pages load best under " \
     "#{HEAVY_BYTES / 1024} KB and #{WIDE_PIXELS} px. #{how_to_shrink(content_type)}."]
  end

  def how_to_shrink(content_type)
    return "Pass max_width=#{WIDE_PIXELS} to store it narrower and lighter" if RESIZABLE.include?(content_type)

    'It cannot be resized here: convert it to WebP (animated or not) before uploading'
  end
end
