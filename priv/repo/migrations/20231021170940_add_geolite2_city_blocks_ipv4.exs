defmodule GeoIpServer.Repo.Migrations.AddGeolite2CityBlocksIpv4 do
  use Ecto.Migration

  def change do
    create table(:geolite2_city_blocks_ipv4, primary_key: false) do
      add(:network, :ip4r, primary_key: true, null: false)
      add(:geoname_id, :bigint)
      add(:registered_country_geoname_id, :bigint)
      add(:represented_country_geoname_id, :bigint)
      add(:is_anonymous_proxy, :boolean, default: false)
      add(:is_satellite_provider, :boolean, default: false)
      add(:postal_code, :string)
      add(:latitude, :float)
      add(:longitude, :float)
      add(:accuracy_radius, :int)
      timestamps()
    end
  end
end
