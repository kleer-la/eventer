# frozen_string_literal: true

# Where a retired service or area sends its traffic: the site answers its URL
# with a 301 to it (#224).
class AddRedirectUrlToServicesAndServiceAreas < ActiveRecord::Migration[8.1]
  def change
    add_column :services, :redirect_url, :string
    add_column :service_areas, :redirect_url, :string
  end
end
