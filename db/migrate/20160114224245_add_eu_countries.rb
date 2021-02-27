# encoding: utf-8

class AddEuCountries < ActiveRecord::Migration[5.0]
    EuCountries = [
      ['GB', 'Gran Bretaña'],
      ['DK', 'Dinamarca'],
      ['IT', 'Italia'],
      ['FR', 'Francia'],
      ['DE', 'Alemania'],
      ['FR', 'Francia'],
      ['BE', 'Bélgica'],
      ['NL', 'Holanda'],
      ['CH', 'Suiza'],
      ['SE', 'Suecia'],
      ['NO', 'Noruega'],
      ['FI', 'Finlandia'],
      ['PL', 'Polonia'],
      ['PT', 'Portugal'],
      ['RO', 'Rumania'],
      ['RU', 'Rusia'],
      ['UA', 'Ucrania'],
      ['SK', 'Eslovaquia'],
      ['SI', 'Eslovenia'],
      ['HR', 'Croacia'],
      ['AT', 'Austria'],
      ['CZ', 'Republica Checa'],
      ['HU', 'Hungría'],
    ]
  def up
    EuCountries.each {|c|
      country= Country.find_by_iso_code( c[0] )
      InfluenceZone.create( zone_name: "",
      tag_name: "ZI-AMS-#{c[0]} (#{c[1]})",
      country_id: country.id )

      country.name = c[1]
      country.save!
    }
  end

  def down
    EuCountries.each {|c|
      country= Country.find_by_iso_code( c[0] )
      InfluenceZone.find_by_country_id(country.id).delete
    }
  end
end
