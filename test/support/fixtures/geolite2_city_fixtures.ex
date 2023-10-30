defmodule GeoIpServer.Geolite2CityFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GeoIpServer.Geolite2City` context.
  """

  alias GeoIpServer.Geolite2City

  @doc """
  Generate a BlockIpv4 entity.
  """
  def block_ipv4_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      network: "1.0.77.0/24",
      geoname_id: 1,
      registered_country_geoname_id: 1,
      represented_country_geoname_id: 1,
      is_anonymous_proxy: false,
      is_satellite_provider: false,
      postal_code: "10000",
      latitude: 45.8150,
      longitude: 15.9819,
      accuracy_radius: 100,
      inserted_at: ~U[2023-10-27 10:34:00Z],
      updated_at: ~U[2023-10-27 10:34:00Z]
    })
    |> Geolite2City.create_block_ipv4!()
  end

  def block_ipv6_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      network: "2001:db8::/32",
      geoname_id: 1,
      registered_country_geoname_id: 1,
      represented_country_geoname_id: 1,
      is_anonymous_proxy: false,
      is_satellite_provider: false,
      postal_code: "10000",
      latitude: 45.8150,
      longitude: 15.9819,
      accuracy_radius: 100,
      inserted_at: ~U[2023-10-27 10:34:00Z],
      updated_at: ~U[2023-10-27 10:34:00Z]
    })
    |> Geolite2City.create_block_ipv6!()
  end

  def location_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      geoname_id: 1,
      locale_code: "en",
      continent_code: "EU",
      continent_name: "Europe",
      country_iso_code: "HR",
      country_name: "Croatia",
      subdivision_1_iso_code: "ABC",
      subdivision_1_name: "Grad Zagreb",
      subdivision_2_iso_code: nil,
      subdivision_2_name: nil,
      city_name: "Zagreb",
      metro_code: nil,
      time_zone: "Europe/Zagreb",
      is_in_european_union: true,
      inserted_at: ~U[2023-10-27 10:34:00Z],
      updated_at: ~U[2023-10-27 10:34:00Z]
    })
    |> Geolite2City.create_location!()
  end
end
