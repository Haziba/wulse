module ApplicationHelper
  include Pagy::Frontend

  def current_page_starts_with?(path)
    request.path.start_with?(path)
  end

  def generate_color_shades(hex_color)
    # Remove # if present
    hex = hex_color.gsub("#", "")

    # Convert hex to RGB
    r = hex[0..1].to_i(16)
    g = hex[2..3].to_i(16)
    b = hex[4..5].to_i(16)

    # Generate shades by mixing with white and black
    shades = {}

    # Lighter shades (50-400) - mix with white
    shades[50] = mix_colors(r, g, b, 255, 255, 255, 0.95)
    shades[100] = mix_colors(r, g, b, 255, 255, 255, 0.85)
    shades[200] = mix_colors(r, g, b, 255, 255, 255, 0.65)
    shades[300] = mix_colors(r, g, b, 255, 255, 255, 0.45)
    shades[400] = mix_colors(r, g, b, 255, 255, 255, 0.25)

    # Base color (500)
    shades[500] = hex_color

    # Darker shades (600-900) - mix with black
    shades[600] = mix_colors(r, g, b, 0, 0, 0, 0.15)
    shades[700] = mix_colors(r, g, b, 0, 0, 0, 0.30)
    shades[800] = mix_colors(r, g, b, 0, 0, 0, 0.45)
    shades[900] = mix_colors(r, g, b, 0, 0, 0, 0.60)

    shades
  end

  private

  def mix_colors(r1, g1, b1, r2, g2, b2, ratio)
    r = (r1 + (r2 - r1) * ratio).round.clamp(0, 255)
    g = (g1 + (g2 - g1) * ratio).round.clamp(0, 255)
    b = (b1 + (b2 - b1) * ratio).round.clamp(0, 255)

    "#%02x%02x%02x" % [ r, g, b ]
  end
end
