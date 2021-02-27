# encoding: utf-8

class SeedInfluenceZones < ActiveRecord::Migration
  def up
    if (Country.count == 0)
      Country.create([
        {:name => '-- OnLine --', :iso_code => 'OL'},
        {:name => 'Albania', :iso_code => 'AL'},
        {:name => 'Algeria', :iso_code => 'DZ'},
        {:name => 'American Samoa', :iso_code => 'AS'},
        {:name => 'Andorra', :iso_code => 'AD'},
        {:name => 'Angola', :iso_code => 'AO'},
        {:name => 'Anguilla', :iso_code => 'AI'},
        {:name => 'Antarctica', :iso_code => 'AQ'},
        {:name => 'Antigua and Barbuda', :iso_code => 'AG'},
        {:name => 'Argentina', :iso_code => 'AR'},
        {:name => 'Armenia', :iso_code => 'AM'},
        {:name => 'Aruba', :iso_code => 'AW'},
        {:name => 'Australia', :iso_code => 'AU'},
        {:name => 'Austria', :iso_code => 'AT'},
        {:name => 'Azerbaijan', :iso_code => 'AZ'},
        {:name => 'Bahamas', :iso_code => 'BS'},
        {:name => 'Bahrain', :iso_code => 'BH'},
        {:name => 'Bangladesh', :iso_code => 'BD'},
        {:name => 'Barbados', :iso_code => 'BB'},
        {:name => 'Belarus', :iso_code => 'BY'},
        {:name => 'Belgium', :iso_code => 'BE'},
        {:name => 'Belize', :iso_code => 'BZ'},
        {:name => 'Benin', :iso_code => 'BJ'},
        {:name => 'Bermuda', :iso_code => 'BM'},
        {:name => 'Bhutan', :iso_code => 'BT'},
        {:name => 'Bolivia', :iso_code => 'BO'},
        {:name => 'Bosnia and Herzegovina', :iso_code => 'BA'},
        {:name => 'Botswana', :iso_code => 'BW'},
        {:name => 'Bouvet Island', :iso_code => 'BV'},
        {:name => 'Brazil', :iso_code => 'BR'},
        {:name => 'British Indian Ocean Territory', :iso_code => 'IO'},
        {:name => 'Brunei Darussalam', :iso_code => 'BN'},
        {:name => 'Bulgaria', :iso_code => 'BG'},
        {:name => 'Burkina Faso', :iso_code => 'BF'},
        {:name => 'Burundi', :iso_code => 'BI'},
        {:name => 'Cambodia', :iso_code => 'KH'},
        {:name => 'Cameroon', :iso_code => 'CM'},
        {:name => 'Canada', :iso_code => 'CA'},
        {:name => 'Cape Verde', :iso_code => 'CV'},
        {:name => 'Cayman Islands', :iso_code => 'KY'},
        {:name => 'Central African Republic', :iso_code => 'CF'},
        {:name => 'Chad', :iso_code => 'TD'},
        {:name => 'Chile', :iso_code => 'CL'},
        {:name => 'China', :iso_code => 'CN'},
        {:name => 'Christmas Island', :iso_code => 'CX'},
        {:name => 'Cocos (Keeling) Islands', :iso_code => 'CC'},
        {:name => 'Colombia', :iso_code => 'CO'},
        {:name => 'Comoros', :iso_code => 'KM'},
        {:name => 'Congo', :iso_code => 'CG'},
        {:name => 'Congo, The Democratic Republic of The', :iso_code => 'CD'},
        {:name => 'Cook Islands', :iso_code => 'CK'},
        {:name => 'Costa Rica', :iso_code => 'CR'},
        {:name => 'Côte D\'Ivoire', :iso_code => 'CI'},
        {:name => 'Croatia', :iso_code => 'HR'},
        {:name => 'Cuba', :iso_code => 'CU'},
        {:name => 'Cyprus', :iso_code => 'CY'},
        {:name => 'Czech Republic', :iso_code => 'CZ'},
        {:name => 'Denmark', :iso_code => 'DK'},
        {:name => 'Djibouti', :iso_code => 'DJ'},
        {:name => 'Dominica', :iso_code => 'DM'},
        {:name => 'Dominican Republic', :iso_code => 'DO'},
        {:name => 'Ecuador', :iso_code => 'EC'},
        {:name => 'Egypt', :iso_code => 'EG'},
        {:name => 'El Salvador', :iso_code => 'SV'},
        {:name => 'Equatorial Guinea', :iso_code => 'GQ'},
        {:name => 'Eritrea', :iso_code => 'ER'},
        {:name => 'Estonia', :iso_code => 'EE'},
        {:name => 'Ethiopia', :iso_code => 'ET'},
        {:name => 'Falkland Islands (Malvinas)', :iso_code => 'FK'},
        {:name => 'Faroe Islands', :iso_code => 'FO'},
        {:name => 'Fiji', :iso_code => 'FJ'},
        {:name => 'Finland', :iso_code => 'FI'},
        {:name => 'France', :iso_code => 'FR'},
        {:name => 'French Guiana', :iso_code => 'GF'},
        {:name => 'French Polynesia', :iso_code => 'PF'},
        {:name => 'French Southern Territories', :iso_code => 'TF'},
        {:name => 'Gabon', :iso_code => 'GA'},
        {:name => 'Gambia', :iso_code => 'GM'},
        {:name => 'Georgia', :iso_code => 'GE'},
        {:name => 'Germany', :iso_code => 'DE'},
        {:name => 'Ghana', :iso_code => 'GH'},
        {:name => 'Gibraltar', :iso_code => 'GI'},
        {:name => 'Greece', :iso_code => 'GR'},
        {:name => 'Greenland', :iso_code => 'GL'},
        {:name => 'Grenada', :iso_code => 'GD'},
        {:name => 'Guadeloupe', :iso_code => 'GP'},
        {:name => 'Guam', :iso_code => 'GU'},
        {:name => 'Guatemala', :iso_code => 'GT'},
        {:name => 'Guernsey', :iso_code => 'GG'},
        {:name => 'Guinea', :iso_code => 'GN'},
        {:name => 'Guinea-Bissau', :iso_code => 'GW'},
        {:name => 'Guyana', :iso_code => 'GY'},
        {:name => 'Haiti', :iso_code => 'HT'},
        {:name => 'Heard Island and Mcdonald Islands', :iso_code => 'HM'},
        {:name => 'Holy See (Vatican City State)', :iso_code => 'VA'},
        {:name => 'Honduras', :iso_code => 'HN'},
        {:name => 'Hong Kong', :iso_code => 'HK'},
        {:name => 'Hungary', :iso_code => 'HU'},
        {:name => 'Iceland', :iso_code => 'IS'},
        {:name => 'India', :iso_code => 'IN'},
        {:name => 'Indonesia', :iso_code => 'ID'},
        {:name => 'Iran, Islamic Republic of', :iso_code => 'IR'},
        {:name => 'Iraq', :iso_code => 'IQ'},
        {:name => 'Ireland', :iso_code => 'IE'},
        {:name => 'Isle of Man', :iso_code => 'IM'},
        {:name => 'Israel', :iso_code => 'IL'},
        {:name => 'Italy', :iso_code => 'IT'},
        {:name => 'Jamaica', :iso_code => 'JM'},
        {:name => 'Japan', :iso_code => 'JP'},
        {:name => 'Jersey', :iso_code => 'JE'},
        {:name => 'Jordan', :iso_code => 'JO'},
        {:name => 'Kazakhstan', :iso_code => 'KZ'},
        {:name => 'Kenya', :iso_code => 'KE'},
        {:name => 'Kiribati', :iso_code => 'KI'},
        {:name => 'Korea, Democratic People\'s Republic of', :iso_code => 'KP'},
        {:name => 'Korea, Republic of', :iso_code => 'KR'},
        {:name => 'Kuwait', :iso_code => 'KW'},
        {:name => 'Kyrgyzstan', :iso_code => 'KG'},
        {:name => 'Lao People\'s Democratic Republic', :iso_code => 'LA'},
        {:name => 'Latvia', :iso_code => 'LV'},
        {:name => 'Lebanon', :iso_code => 'LB'},
        {:name => 'Lesotho', :iso_code => 'LS'},
        {:name => 'Liberia', :iso_code => 'LR'},
        {:name => 'Libyan Arab Jamahiriya', :iso_code => 'LY'},
        {:name => 'Liechtenstein', :iso_code => 'LI'},
        {:name => 'Lithuania', :iso_code => 'LT'},
        {:name => 'Luxembourg', :iso_code => 'LU'},
        {:name => 'Macao', :iso_code => 'MO'},
        {:name => 'Macedonia, The Former Yugoslav Republic of', :iso_code => 'MK'},
        {:name => 'Madagascar', :iso_code => 'MG'},
        {:name => 'Malawi', :iso_code => 'MW'},
        {:name => 'Malaysia', :iso_code => 'MY'},
        {:name => 'Maldives', :iso_code => 'MV'},
        {:name => 'Mali', :iso_code => 'ML'},
        {:name => 'Malta', :iso_code => 'MT'},
        {:name => 'Marshall Islands', :iso_code => 'MH'},
        {:name => 'Martinique', :iso_code => 'MQ'},
        {:name => 'Mauritania', :iso_code => 'MR'},
        {:name => 'Mauritius', :iso_code => 'MU'},
        {:name => 'Mayotte', :iso_code => 'YT'},
        {:name => 'Mexico', :iso_code => 'MX'},
        {:name => 'Micronesia, Federated States of', :iso_code => 'FM'},
        {:name => 'Moldova, Republic of', :iso_code => 'MD'},
        {:name => 'Monaco', :iso_code => 'MC'},
        {:name => 'Mongolia', :iso_code => 'MN'},
        {:name => 'Montenegro', :iso_code => 'ME'},
        {:name => 'Montserrat', :iso_code => 'MS'},
        {:name => 'Morocco', :iso_code => 'MA'},
        {:name => 'Mozambique', :iso_code => 'MZ'},
        {:name => 'Myanmar', :iso_code => 'MM'},
        {:name => 'Namibia', :iso_code => 'NA'},
        {:name => 'Nauru', :iso_code => 'NR'},
        {:name => 'Nepal', :iso_code => 'NP'},
        {:name => 'Netherlands', :iso_code => 'NL'},
        {:name => 'Netherlands Antilles', :iso_code => 'AN'},
        {:name => 'New Caledonia', :iso_code => 'NC'},
        {:name => 'New Zealand', :iso_code => 'NZ'},
        {:name => 'Nicaragua', :iso_code => 'NI'},
        {:name => 'Niger', :iso_code => 'NE'},
        {:name => 'Nigeria', :iso_code => 'NG'},
        {:name => 'Niue', :iso_code => 'NU'},
        {:name => 'Norfolk Island', :iso_code => 'NF'},
        {:name => 'Northern Mariana Islands', :iso_code => 'MP'},
        {:name => 'Norway', :iso_code => 'NO'},
        {:name => 'Oman', :iso_code => 'OM'},
        {:name => 'Pakistan', :iso_code => 'PK'},
        {:name => 'Palau', :iso_code => 'PW'},
        {:name => 'Palestinian Territory, Occupied', :iso_code => 'PS'},
        {:name => 'Panama', :iso_code => 'PA'},
        {:name => 'Papua New Guinea', :iso_code => 'PG'},
        {:name => 'Paraguay', :iso_code => 'PY'},
        {:name => 'Peru', :iso_code => 'PE'},
        {:name => 'Philippines', :iso_code => 'PH'},
        {:name => 'Pitcairn', :iso_code => 'PN'},
        {:name => 'Poland', :iso_code => 'PL'},
        {:name => 'Portugal', :iso_code => 'PT'},
        {:name => 'Puerto Rico', :iso_code => 'PR'},
        {:name => 'Qatar', :iso_code => 'QA'},
        {:name => 'Réunion', :iso_code => 'RE'},
        {:name => 'Romania', :iso_code => 'RO'},
        {:name => 'Russian Federation', :iso_code => 'RU'},
        {:name => 'Rwanda', :iso_code => 'RW'},
        {:name => 'Saint Barthélemy', :iso_code => 'BL'},
        {:name => 'Saint Helena, Ascension and Tristan Da Cunha', :iso_code => 'SH'},
        {:name => 'Saint Kitts and Nevis', :iso_code => 'KN'},
        {:name => 'Saint Lucia', :iso_code => 'LC'},
        {:name => 'Saint Martin', :iso_code => 'MF'},
        {:name => 'Saint Pierre and Miquelon', :iso_code => 'PM'},
        {:name => 'Saint Vincent and The Grenadines', :iso_code => 'VC'},
        {:name => 'Samoa', :iso_code => 'WS'},
        {:name => 'San Marino', :iso_code => 'SM'},
        {:name => 'Sao Tome and Principe', :iso_code => 'ST'},
        {:name => 'Saudi Arabia', :iso_code => 'SA'},
        {:name => 'Senegal', :iso_code => 'SN'},
        {:name => 'Serbia', :iso_code => 'RS'},
        {:name => 'Seychelles', :iso_code => 'SC'},
        {:name => 'Sierra Leone', :iso_code => 'SL'},
        {:name => 'Singapore', :iso_code => 'SG'},
        {:name => 'Slovakia', :iso_code => 'SK'},
        {:name => 'Slovenia', :iso_code => 'SI'},
        {:name => 'Solomon Islands', :iso_code => 'SB'},
        {:name => 'Somalia', :iso_code => 'SO'},
        {:name => 'South Africa', :iso_code => 'ZA'},
        {:name => 'South Georgia and The South Sandwich Islands', :iso_code => 'GS'},
        {:name => 'Spain', :iso_code => 'ES'},
        {:name => 'Sri Lanka', :iso_code => 'LK'},
        {:name => 'Sudan', :iso_code => 'SD'},
        {:name => 'Suriname', :iso_code => 'SR'},
        {:name => 'Svalbard and Jan Mayen', :iso_code => 'SJ'},
        {:name => 'Swaziland', :iso_code => 'SZ'},
        {:name => 'Sweden', :iso_code => 'SE'},
        {:name => 'Switzerland', :iso_code => 'CH'},
        {:name => 'Syrian Arab Republic', :iso_code => 'SY'},
        {:name => 'Taiwan, Province of China', :iso_code => 'TW'},
        {:name => 'Tajikistan', :iso_code => 'TJ'},
        {:name => 'Tanzania, United Republic of', :iso_code => 'TZ'},
        {:name => 'Thailand', :iso_code => 'TH'},
        {:name => 'Timor-Leste', :iso_code => 'TL'},
        {:name => 'Togo', :iso_code => 'TG'},
        {:name => 'Tokelau', :iso_code => 'TK'},
        {:name => 'Tonga', :iso_code => 'TO'},
        {:name => 'Trinidad and Tobago', :iso_code => 'TT'},
        {:name => 'Tunisia', :iso_code => 'TN'},
        {:name => 'Turkey', :iso_code => 'TR'},
        {:name => 'Turkmenistan', :iso_code => 'TM'},
        {:name => 'Turks and Caicos Islands', :iso_code => 'TC'},
        {:name => 'Tuvalu', :iso_code => 'TV'},
        {:name => 'Uganda', :iso_code => 'UG'},
        {:name => 'Ukraine', :iso_code => 'UA'},
        {:name => 'United Arab Emirates', :iso_code => 'AE'},
        {:name => 'United Kingdom', :iso_code => 'GB'},
        {:name => 'United States', :iso_code => 'US'},
        {:name => 'United States Minor Outlying Islands', :iso_code => 'UM'},
        {:name => 'Uruguay', :iso_code => 'UY'},
        {:name => 'Uzbekistan', :iso_code => 'UZ'},
        {:name => 'Vanuatu', :iso_code => 'VU'},
        {:name => 'Venezuela, Bolivarian Republic of', :iso_code => 'VE'},
        {:name => 'Viet Nam', :iso_code => 'VN'},
        {:name => 'Virgin Islands, British', :iso_code => 'VG'},
        {:name => 'Virgin Islands, U.S.', :iso_code => 'VI'},
        {:name => 'Wallis and Futuna', :iso_code => 'WF'},
        {:name => 'Western Sahara', :iso_code => 'EH'},
        {:name => 'Yemen', :iso_code => 'YE'},
        {:name => 'Zambia', :iso_code => 'ZM'},
        {:name => 'Zimbabwe', :iso_code => 'ZW'}
      ])
    end
    
    InfluenceZone.create( zone_name: 'Neuquen', tag_name: 'ZI-AMS-AR-PAT (Patagonia)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Santa Cruz', tag_name: 'ZI-AMS-AR-PAT (Patagonia)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Chubut', tag_name: 'ZI-AMS-AR-PAT (Patagonia)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Tierra del Fuego', tag_name: 'ZI-AMS-AR-PAT (Patagonia)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Capital Federal', tag_name: 'ZI-AMS-AR-BUE (Buenos Aires)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Buenos Aires', tag_name: 'ZI-AMS-AR-BUE (Buenos Aires)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Córdoba', tag_name: 'ZI-AMS-AR-CTR (Centro)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'La Pampa', tag_name: 'ZI-AMS-AR-CTR (Centro)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Santa Fé', tag_name: 'ZI-AMS-AR-CTR (Centro)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Corrientes', tag_name: 'ZI-AMS-AR-LIT (Litoral)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Misiones', tag_name: 'ZI-AMS-AR-LIT (Litoral)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Entre Rios', tag_name: 'ZI-AMS-AR-LIT (Litoral)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Chaco', tag_name: 'ZI-AMS-AR-LIT (Litoral)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Formosa', tag_name: 'ZI-AMS-AR-LIT (Litoral)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Santiago del Estero', tag_name: 'ZI-AMS-AR-NOA (Noroeste)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Tucumán', tag_name: 'ZI-AMS-AR-NOA (Noroeste)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'La Rioja', tag_name: 'ZI-AMS-AR-NOA (Noroeste)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Salta', tag_name: 'ZI-AMS-AR-NOA (Noroeste)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Jujuy', tag_name: 'ZI-AMS-AR-NOA (Noroeste)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Catamarca', tag_name: 'ZI-AMS-AR-NOA (Noroeste)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'Mendoza', tag_name: 'ZI-AMS-AR-CUY (Cuyo)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'San Juan', tag_name: 'ZI-AMS-AR-CUY (Cuyo)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: 'San Luis', tag_name: 'ZI-AMS-AR-CUY (Cuyo)', country_id: Country.find_by_iso_code( 'AR' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AUS (Australia)', country_id: Country.find_by_iso_code( 'AU' ).id )
    InfluenceZone.create( zone_name: 'Cochabamba', tag_name: 'ZI-AMS-BO (Bolivia)', country_id: Country.find_by_iso_code( 'BO' ).id )
    InfluenceZone.create( zone_name: 'La Paz', tag_name: 'ZI-AMS-BO (Bolivia)', country_id: Country.find_by_iso_code( 'BO' ).id )
    InfluenceZone.create( zone_name: 'Santa Cruz', tag_name: 'ZI-AMS-BO (Bolivia)', country_id: Country.find_by_iso_code( 'BO' ).id )
    InfluenceZone.create( zone_name: 'Tarija', tag_name: 'ZI-AMS-BO (Bolivia)', country_id: Country.find_by_iso_code( 'BO' ).id )
    InfluenceZone.create( zone_name: 'Pando', tag_name: 'ZI-AMS-BO (Bolivia)', country_id: Country.find_by_iso_code( 'BO' ).id )
    InfluenceZone.create( zone_name: 'Potosí', tag_name: 'ZI-AMS-BO (Bolivia)', country_id: Country.find_by_iso_code( 'BO' ).id )
    InfluenceZone.create( zone_name: 'Oruro', tag_name: 'ZI-AMS-BO (Bolivia)', country_id: Country.find_by_iso_code( 'BO' ).id )
    InfluenceZone.create( zone_name: 'Chuquisaca', tag_name: 'ZI-AMS-BO (Bolivia)', country_id: Country.find_by_iso_code( 'BO' ).id )
    InfluenceZone.create( zone_name: 'Beni', tag_name: 'ZI-AMS-BO (Bolivia)', country_id: Country.find_by_iso_code( 'BO' ).id )
    InfluenceZone.create( zone_name: 'Acre', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Alagoas', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Rio de Janeiro', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Sao Paulo', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Amapá', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Amazonas', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Bahia', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Ceará', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Espírito Santo', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Goiás', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Mato Grosso', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Mato Grosso do Sul', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Minas Gerais', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Pará', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Paraíba', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Paraná', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Pernambuco', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Piauí', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Rio de Janeiro', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Rio Grande do Norte', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Rio Grande do Sul', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Rondônia', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Roraima', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Santa Catarina', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'São Paulo', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Sergipe', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: 'Tocantins', tag_name: 'ZI-AMS-BR (Brasil)', country_id: Country.find_by_iso_code( 'BR' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AMN-CA (Canada)', country_id: Country.find_by_iso_code( 'CA' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AMS-CL (Chile)', country_id: Country.find_by_iso_code( 'CL' ).id )
    InfluenceZone.create( zone_name: 'Armenia', tag_name: 'ZI-AMS-CO-EJE (Eje cafetero)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Pereira', tag_name: 'ZI-AMS-CO-EJE (Eje cafetero)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Manizales', tag_name: 'ZI-AMS-CO-EJE (Eje cafetero)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Barranquilla', tag_name: 'ZI-AMS-CO-CAR (Caribe)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Cartagena', tag_name: 'ZI-AMS-CO-CAR (Caribe)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Santa Marta', tag_name: 'ZI-AMS-CO-CAR (Caribe)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Monteria', tag_name: 'ZI-AMS-CO-CAR (Caribe)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Valledupar', tag_name: 'ZI-AMS-CO-CAR (Caribe)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Sincelejo', tag_name: 'ZI-AMS-CO-CAR (Caribe)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Bogota', tag_name: 'ZI-AMS-CO-BOG (Bogota)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Tunja', tag_name: 'ZI-AMS-CO-BOG (Bogota)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Villavicencio', tag_name: 'ZI-AMS-CO-BOG (Bogota)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Neiva', tag_name: 'ZI-AMS-CO-BOG (Bogota)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Ibagué', tag_name: 'ZI-AMS-CO-BOG (Bogota)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Bucaramanga', tag_name: 'ZI-AMS-CO-SAN (Santander)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Cúcuta', tag_name: 'ZI-AMS-CO-SAN (Santander)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Cali', tag_name: 'ZI-AMS-CO-PAC (Pacífico)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Popayan', tag_name: 'ZI-AMS-CO-PAC (Pacífico)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Pasto', tag_name: 'ZI-AMS-CO-PAC (Pacífico)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Quibdó', tag_name: 'ZI-AMS-CO-PAC (Pacífico)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'Medellin', tag_name: 'ZI-AMS-CO-MDE (Medellín)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: 'N/A', tag_name: 'ZI-AMS-CO-BOG (Bogota)', country_id: Country.find_by_iso_code( 'CO' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AMC (America Central y Caribe)', country_id: Country.find_by_iso_code( 'CU' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AMC (America Central y Caribe)', country_id: Country.find_by_iso_code( 'GT' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AMC (America Central y Caribe)', country_id: Country.find_by_iso_code( 'HN' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AMS-EC (Ecuador)', country_id: Country.find_by_iso_code( 'EC' ).id )
    InfluenceZone.create( zone_name: 'Andalucía', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Aragón', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Principado de Asturias', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Islas Baleares', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Canarias', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Cantabria', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Castila-La Mancha', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Castilla y León', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Cataluña', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Comunidad Valenciana', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Extremadura', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Galicia', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'La Rioja', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Comunidad de Madrid', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Comunidad Foral de Navarra', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'País Vasco', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Región de Murcia', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Ceuta', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: 'Melilla', tag_name: 'ZI-EUR-ES (España)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-ASI (Asia)', country_id: Country.find_by_iso_code( 'ES' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AMN-MX (Mexico)', country_id: Country.find_by_iso_code( 'MX' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AMC (America Central y Caribe)', country_id: Country.find_by_iso_code( 'PA' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AMS-PY (Paraguay)', country_id: Country.find_by_iso_code( 'PY' ).id )
    InfluenceZone.create( zone_name: 'Amazonas', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Áncash', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Apurímac', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Arequipa', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Ayacucho', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Cajamarca', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Callao', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Cusco', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Huancavelica', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Huánuco', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Ica', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Junín', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'La Libertad', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Lambayeque', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Lima', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Loreto', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Madre de Dios', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Moquegua', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Pasco', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Piura', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Puno', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'San Martín', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Tacna', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Tumbes', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: 'Ucayali', tag_name: 'ZI-AMS-PE (Peru)', country_id: Country.find_by_iso_code( 'PE' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AMC (America Central y Caribe)', country_id: Country.find_by_iso_code( 'DO' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AMS-UY (Uruguay)', country_id: Country.find_by_iso_code( 'UY' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AMN-US (EEUU)', country_id: Country.find_by_iso_code( 'US' ).id )
    InfluenceZone.create( zone_name: '', tag_name: 'ZI-AMS-VE (Venezuela)', country_id: Country.find_by_iso_code( 'VE' ).id )
    
    br = Country.find_by_iso_code( 'BR' )
    br.name = "Brasil"
    br.save!
    
    es = Country.find_by_iso_code( 'ES' )
    es.name = "España"
    es.save!
    
    dom = Country.find_by_iso_code( 'DO' )
    dom.name = "República Dominicana"
    dom.save!
    
    us = Country.find_by_iso_code( 'US' )
    us.name = "Estados Unidos"
    us.save!
    
    ve = Country.find_by_iso_code( 'VE' )
    ve.name = "Venezuela"
    ve.save!    
  end

  def down
    InfluenceZone.delete_all
  end
end
