# frozen_string_literal: true

class CountryFilter
  def initialize(country_iso, previous_ci = nil)
    country_iso ||= previous_ci
    @country_iso = country_iso unless !country_iso.nil? && country_iso.length > 2

    @country_id = nil
    unless @country_iso.nil?
      c = Country.find_by_iso_code(@country_iso.upcase)
      @country_id = c.nil? ? 0 : c.id
    end
  end

  def select?(country_id)
    @country_id.nil? || @country_id == country_id
  end

  attr_reader :country_iso
end
