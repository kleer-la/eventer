# app/models/custom_spider.rb
require 'gruff'

class CustomSpider < Gruff::Spider
  def draw_graph
    # Setup basic positioning
    radius = @graph_height / 2.0
    center_x = @graph_left + (@graph_width / 2.0)
    center_y = @graph_top + (@graph_height / 2.0) - 25 # Move graph up a bit

    @unit_length = radius / @max_value

    additive_angle = (2 * Math::PI) / store.length

    # Draw axes
    draw_axes(center_x, center_y, radius, additive_angle) unless @hide_axes

    # Draw scale circles and labels
    draw_scale_circles_and_labels(center_x, center_y, radius) unless @hide_axes

    # Draw polygon
    draw_polygon(center_x, center_y, additive_angle)
  end

  private

  def draw_scale_circles_and_labels(center_x, center_y, max_radius)
    (1..@max_value).each do |level|
      current_radius = level * @unit_length
      color = 'grey' # Use grey for the lines
      width = 1.0

      draw_unfilled_circle(center_x, center_y, current_radius, color, width)

      # Label the scale (e.g., 1 to 5)
      draw_scale_label(center_x, center_y, current_radius, level) unless @hide_text
    end
  end

  def draw_scale_label(center_x, center_y, radius, level)
    angle = 0 # Place label at the top for simplicity, adjust as needed
    metrics = text_metrics(@marker_font, level.to_s)

    x = center_x + (radius * Math.cos(angle)) - (metrics.width * 1.1)
    y = center_y + (radius * Math.sin(angle)) - (metrics.height / 2.0)

    draw_label_at(metrics.width, metrics.height, x, y, level.to_s, gravity: Magick::CenterGravity)
  end

  def draw_unfilled_circle(center_x, center_y, radius, color, width)
    # Approximate a circle by drawing a polyline with many points
    points = []
    num_segments = 100 # Number of segments to approximate a circle
    angle_step = (2 * Math::PI) / num_segments

    (0..num_segments).each do |i|
      angle = i * angle_step
      x = center_x + (radius * Math.cos(angle))
      y = center_y + (radius * Math.sin(angle))
      points << x
      points << y
    end

    # Draw the polyline (closed loop to form a circle)
    Gruff::Renderer::Polyline.new(renderer, color:, width:).render(points)
  end
end
