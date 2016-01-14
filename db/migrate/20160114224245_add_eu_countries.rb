# encoding: utf-8
class AddEuCountries < ActiveRecord::Migration
  def up
    eu= [
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
      ['HR', 'Coacia'],
      ['AT', 'Austria'],
      ['CZ', 'Republica Checa'],
      ['HU', 'Hungría'],
    ]

    eu.each {|c|
      InfluenceZone.create( zone_name: c[1],
      tag_name: "ZI-AMS-#{c[0]} (#{c[1]})",
      country_id: Country.find_by_iso_code( c[0] ).id )
    }
  end

  def down
  end
end
