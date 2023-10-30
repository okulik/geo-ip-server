defmodule GeoIpServer.GeoDataTest.Location do
  use GeoIpServer.DataCase

  import GeoIpServer.Geolite2CityFixtures

  alias GeoIpServer.Geolite2City
  alias GeoIpServer.Geolite2City.Location

  describe "geolite city2 tests" do
    test "get_location/1 returns the data for the existing location" do
      loc = location_fixture()

      {:ok, location} = Geolite2City.get_location(loc.geoname_id)
      assert %Location{} = location
      assert location.geoname_id == loc.geoname_id
      assert location.locale_code == loc.locale_code
      assert location.continent_code == loc.continent_code
      assert location.continent_name == loc.continent_name
      assert location.country_iso_code == loc.country_iso_code
      assert location.country_name == loc.country_name
      assert location.subdivision_1_iso_code == loc.subdivision_1_iso_code
      assert location.subdivision_1_name == loc.subdivision_1_name
      assert location.subdivision_2_iso_code == loc.subdivision_2_iso_code
      assert location.subdivision_2_name == loc.subdivision_2_name
      assert location.city_name == loc.city_name
      assert location.metro_code == loc.metro_code
      assert location.time_zone == loc.time_zone
      assert location.is_in_european_union == loc.is_in_european_union
      assert location.inserted_at == loc.inserted_at
    end

    test "get_location/1 returns error for a non-existing location" do
      assert Geolite2City.get_location(999_999) == {:error, :not_found}
    end

    test "create_location!/1 with valid attributes creates Location struct" do
      attrs = %{
        geoname_id: 123,
        locale_code: "en",
        continent_code: "EU",
        continent_name: "Europe",
        country_iso_code: "HR",
        country_name: "Croatia",
        subdivision_1_iso_code: "21",
        subdivision_1_name: "Istarska Županija",
        subdivision_2_iso_code: "21",
        subdivision_2_name: "Medulin",
        city_name: "Medulin",
        metro_code: 42,
        time_zone: "Europe/Zagreb",
        is_in_european_union: true,
        inserted_at: ~U[2023-10-08 02:00:00Z],
        updated_at: ~U[2023-10-08 02:00:00Z]
      }

      loc = Geolite2City.create_location!(attrs)
      assert %Location{} = loc
      assert loc.geoname_id == 123
      assert loc.locale_code == "en"
      assert loc.continent_code == "EU"
      assert loc.continent_name == "Europe"
      assert loc.country_iso_code == "HR"
      assert loc.country_name == "Croatia"
      assert loc.subdivision_1_iso_code == "21"
      assert loc.subdivision_1_name == "Istarska Županija"
      assert loc.subdivision_2_iso_code == "21"
      assert loc.subdivision_2_name == "Medulin"
      assert loc.city_name == "Medulin"
      assert loc.metro_code == 42
      assert loc.time_zone == "Europe/Zagreb"
      assert loc.is_in_european_union == true
    end

    test "create_location!/1 with invalid data returns error" do
      assert_raise(Ecto.InvalidChangesetError, fn ->
        Geolite2City.create_location!(%{})
      end)
    end
  end
end
