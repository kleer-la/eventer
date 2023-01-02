# frozen_string_literal: true

class AddEuCountries < ActiveRecord::Migration[4.2]
  EuCountries = [
    ['GB', 'Gran Bretaña'],
    %w[DK Dinamarca],
    %w[IT Italia],
    %w[FR Francia],
    %w[DE Alemania],
    %w[FR Francia],
    %w[BE Bélgica],
    %w[NL Holanda],
    %w[CH Suiza],
    %w[SE Suecia],
    %w[NO Noruega],
    %w[FI Finlandia],
    %w[PL Polonia],
    %w[PT Portugal],
    %w[RO Rumania],
    %w[RU Rusia],
    %w[UA Ucrania],
    %w[SK Eslovaquia],
    %w[SI Eslovenia],
    %w[HR Croacia],
    %w[AT Austria],
    ['CZ', 'Republica Checa'],
    %w[HU Hungría]
  ].freeze
  def up
    EuCountries.each do |c|
      country = Country.find_by_iso_code(c[0])
      InfluenceZone.create(zone_name: '',
                           tag_name: "ZI-AMS-#{c[0]} (#{c[1]})",
                           country_id: country.id)

      country.name = c[1]
      country.save!
    end
  end

  def down
    EuCountries.each do |c|
      country = Country.find_by_iso_code(c[0])
      InfluenceZone.find_by_country_id(country.id).delete
    end
  end
end
