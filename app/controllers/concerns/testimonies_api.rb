# frozen_string_literal: true

# The shape in which the site reads a course's or an area's testimonies:
# fname/lname (the legacy participant names), plain text, and who speaks.
# A testimony is a Testimony, or a Participant while a course still has only
# the legacy ones; those bring no role or company.
module TestimoniesApi
  def format_testimonies_for_api(testimonies)
    testimonies.map do |testimony|
      if testimony.is_a?(Testimony)
        testimony.api_json
      else
        { fname: testimony.fname, lname: testimony.lname, role: nil, company: nil,
          testimony: testimony.testimony, profile_url: testimony.profile_url, photo_url: testimony.photo_url }
      end
    end
  end
end
