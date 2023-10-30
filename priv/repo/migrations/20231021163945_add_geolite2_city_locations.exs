defmodule GeoIpServer.Repo.Migrations.AddGeolite2CityLocations do
  use Ecto.Migration

  def change do
    create table(:geolite2_city_locations, primary_key: false) do
      add(:geoname_id, :bigint, primary_key: true, null: false)
      add(:locale_code, :string, size: 2, null: false)
      add(:continent_code, :string, size: 2, null: false)
      add(:continent_name, :string, null: false)
      add(:country_iso_code, :string, size: 2)
      add(:country_name, :string)
      add(:subdivision_1_iso_code, :string, size: 3)
      add(:subdivision_1_name, :string)
      add(:subdivision_2_iso_code, :string, size: 3)
      add(:subdivision_2_name, :string)
      add(:city_name, :string)
      add(:metro_code, :int)
      add(:time_zone, :string, null: false)
      add(:is_in_european_union, :boolean, null: false)
      timestamps()
    end
  end
end
