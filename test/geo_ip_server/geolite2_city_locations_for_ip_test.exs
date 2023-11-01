defmodule GeoIpServer.GeoDataTest.LocationsForIp do
  use GeoIpServer.DataCase

  import GeoIpServer.Geolite2CityFixtures

  alias GeoIpServer.Geolite2City

  describe "geolite city2 tests" do
    test "get_locations_for_ip/1 returns the data for the existing location" do
      loc = location_fixture()

      block_ipv4_fixture(%{
        geoname_id: loc.geoname_id,
        network: "10.0.0.0/8"
      })

      block_ipv6_fixture(%{
        geoname_id: loc.geoname_id,
        network: "2001:218:c000::/50"
      })

      ret = Geolite2City.get_locations_for_ip("10.0.0.0")
      assert {:ok, [rec]} = ret
      assert rec["geoname_id"] == loc.geoname_id
      assert rec["locale_code"] == loc.locale_code
      assert rec["continent_code"] == loc.continent_code
      assert rec["continent_name"] == loc.continent_name
      assert rec["country_iso_code"] == loc.country_iso_code
      assert rec["country_name"] == loc.country_name
      assert rec["subdivision_1_iso_code"] == loc.subdivision_1_iso_code
      assert rec["subdivision_1_name"] == loc.subdivision_1_name
      assert rec["subdivision_2_iso_code"] == loc.subdivision_2_iso_code
      assert rec["subdivision_2_name"] == loc.subdivision_2_name
      assert rec["city_name"] == loc.city_name
      assert rec["metro_code"] == loc.metro_code
      assert rec["time_zone"] == loc.time_zone
      assert rec["is_in_european_union"] == loc.is_in_european_union

      ret = Geolite2City.get_locations_for_ip("2001:218:c000::")
      assert {:ok, [rec]} = ret
      assert rec["geoname_id"] == loc.geoname_id
      assert rec["locale_code"] == loc.locale_code
      assert rec["continent_code"] == loc.continent_code
      assert rec["continent_name"] == loc.continent_name
      assert rec["country_iso_code"] == loc.country_iso_code
      assert rec["country_name"] == loc.country_name
      assert rec["subdivision_1_iso_code"] == loc.subdivision_1_iso_code
      assert rec["subdivision_1_name"] == loc.subdivision_1_name
      assert rec["subdivision_2_iso_code"] == loc.subdivision_2_iso_code
      assert rec["subdivision_2_name"] == loc.subdivision_2_name
      assert rec["city_name"] == loc.city_name
      assert rec["metro_code"] == loc.metro_code
      assert rec["time_zone"] == loc.time_zone
      assert rec["is_in_european_union"] == loc.is_in_european_union
    end

    test "get_locations_for_ip/1 returns [] when record is missing" do
      assert Geolite2City.get_locations_for_ip("1.2.3.4") == {:ok, []}
    end

    test "get_locations_for_ip/1 returns [] when ip address is invalid" do
      assert Geolite2City.get_locations_for_ip("bad-addr") == {:error, :invalid_ip}
    end
  end
end
