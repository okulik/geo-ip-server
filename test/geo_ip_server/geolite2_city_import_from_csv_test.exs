defmodule GeoIpServer.GeoDataTest.ImportFromCSV do
  use GeoIpServer.DataCase

  alias GeoIpServer.DataImport
  alias GeoIpServer.Geolite2City
  alias GeoIpServer.TestUtils

  describe "geolite city2 tests" do
    test "import_from_csv/1 with a missing file" do
      assert_raise File.Error, ~r/no such file or directory/, fn ->
        Geolite2City.import_csv_file!(
          "/tmp",
          "rand123",
          "no-such-file.csv",
          sha: "some-sha",
          ts: "20231024"
        )
      end
    end

    ##########################################################
    # import_from_stream/3 Geolite2-City-Blocks-IPv4.csv tests
    ##########################################################
    test "import_from_stream/3 for Geolite2-City-Blocks-IPv4.csv with all valid rows" do
      csv = """
      network,geoname_id,registered_country_geoname_id,represented_country_geoname_id,is_anonymous_proxy,is_satellite_provider,postal_code,latitude,longitude,accuracy_radius
      1.0.0.0/24,2077456,2077456,,0,0,,-33.1230,143.4567,1000
      """

      csv
      |> TestUtils.csv_to_stream()
      |> Geolite2City.import_from_stream(
        "GeoLite2-City-Blocks-IPv4.csv",
        sha: "some-sha",
        ts: "20231024"
      )

      {:ok, block_ipv4} = Geolite2City.get_block_ipv4("1.0.0.0/24")
      {:ok, range} = EctoNetwork.CIDR.cast("1.0.0.0/24")
      assert block_ipv4.network == range
      assert block_ipv4.geoname_id == 2_077_456
      assert block_ipv4.registered_country_geoname_id == 2_077_456
      assert block_ipv4.represented_country_geoname_id == nil
      assert block_ipv4.is_anonymous_proxy == false
      assert block_ipv4.is_satellite_provider == false
      assert block_ipv4.postal_code == nil
      assert block_ipv4.latitude == -33.1230
      assert block_ipv4.longitude == 143.4567
      assert block_ipv4.accuracy_radius == 1000

      imp = hd(DataImport.get_all_geolite2_imports())
      assert imp.import_file == "GeoLite2-City-Blocks-IPv4.csv"
      assert imp.import_sha256 == "some-sha"
      assert imp.timestamp == "20231024"
      assert imp.success_count == 1
      assert imp.error_count == 0
    end

    test "import_locations_from_stream/1 for Geolite2-City-Blocks-IPv4.csv with a missing IP address" do
      csv = """
      network,geoname_id,registered_country_geoname_id,represented_country_geoname_id,is_anonymous_proxy,is_satellite_provider,postal_code,latitude,longitude,accuracy_radius
      ,1814991,1814991,,0,0,,34.1234,113.1234,1000
      """

      csv
      |> TestUtils.csv_to_stream()
      |> Geolite2City.import_from_stream(
        "GeoLite2-City-Blocks-IPv4.csv",
        sha: "some-sha",
        ts: "20231024"
      )

      imp = hd(DataImport.get_all_geolite2_imports())
      assert imp.import_file == "GeoLite2-City-Blocks-IPv4.csv"
      assert imp.import_sha256 == "some-sha"
      assert imp.timestamp == "20231024"
      assert imp.success_count == 0
      assert imp.error_count == 1
    end

    test "import_locations_from_stream/1 for Geolite2-City-Blocks-IPv4.csv with invalid IP address" do
      csv = """
      network,geoname_id,registered_country_geoname_id,represented_country_geoname_id,is_anonymous_proxy,is_satellite_provider,postal_code,latitude,longitude,accuracy_radius
      badip,1814991,1814991,,0,0,,34.1234,113.1234,1000
      """

      csv
      |> TestUtils.csv_to_stream()
      |> Geolite2City.import_from_stream(
        "GeoLite2-City-Blocks-IPv4.csv",
        sha: "some-sha",
        ts: "20231024"
      )

      imp = hd(DataImport.get_all_geolite2_imports())
      assert imp.import_file == "GeoLite2-City-Blocks-IPv4.csv"
      assert imp.import_sha256 == "some-sha"
      assert imp.timestamp == "20231024"
      assert imp.success_count == 0
      assert imp.error_count == 1
    end

    ##########################################################
    # import_from_stream/3 Geolite2-City-Blocks-IPv6.csv tests
    ##########################################################
    test "import_from_stream/3 for Geolite2-City-Blocks-IP6v.csv with all valid rows" do
      csv = """
      network,geoname_id,registered_country_geoname_id,represented_country_geoname_id,is_anonymous_proxy,is_satellite_provider,postal_code,latitude,longitude,accuracy_radius
      2a7:1c44:39f3:aa::/64,2657896,,,0,0,8000,47.1234,8.1234,100
      """

      csv
      |> TestUtils.csv_to_stream()
      |> Geolite2City.import_from_stream(
        "GeoLite2-City-Blocks-IPv6.csv",
        sha: "some-sha",
        ts: "20231024"
      )

      {:ok, block_ipv6} = Geolite2City.get_block_ipv6("2a7:1c44:39f3:aa::/64")
      {:ok, range} = EctoNetwork.CIDR.cast("2a7:1c44:39f3:aa::/64")
      assert block_ipv6.network == range
      assert block_ipv6.geoname_id == 2_657_896
      assert block_ipv6.registered_country_geoname_id == nil
      assert block_ipv6.represented_country_geoname_id == nil
      assert block_ipv6.is_anonymous_proxy == false
      assert block_ipv6.is_satellite_provider == false
      assert block_ipv6.postal_code == "8000"
      assert block_ipv6.latitude == 47.1234
      assert block_ipv6.longitude == 8.1234
      assert block_ipv6.accuracy_radius == 100

      imp = hd(DataImport.get_all_geolite2_imports())
      assert imp.import_file == "GeoLite2-City-Blocks-IPv6.csv"
      assert imp.import_sha256 == "some-sha"
      assert imp.timestamp == "20231024"
      assert imp.success_count == 1
      assert imp.error_count == 0
    end

    test "import_locations_from_stream/1 for Geolite2-City-Blocks-IPv6.csv with a missing IP address" do
      csv = """
      network,geoname_id,registered_country_geoname_id,represented_country_geoname_id,is_anonymous_proxy,is_satellite_provider,postal_code,latitude,longitude,accuracy_radius
      ,2657896,,,0,0,8000,47.1234,8.1234,100
      """

      csv
      |> TestUtils.csv_to_stream()
      |> Geolite2City.import_from_stream(
        "GeoLite2-City-Blocks-IPv6.csv",
        sha: "some-sha",
        ts: "20231024"
      )

      imp = hd(DataImport.get_all_geolite2_imports())
      assert imp.import_file == "GeoLite2-City-Blocks-IPv6.csv"
      assert imp.import_sha256 == "some-sha"
      assert imp.timestamp == "20231024"
      assert imp.success_count == 0
      assert imp.error_count == 1
    end

    test "import_locations_from_stream/1 for Geolite2-City-Blocks-IPv6.csv with invalid IP address" do
      csv = """
      network,geoname_id,registered_country_geoname_id,represented_country_geoname_id,is_anonymous_proxy,is_satellite_provider,postal_code,latitude,longitude,accuracy_radius
      badip,2657896,,,0,0,8000,47.1234,8.1234,100
      """

      csv
      |> TestUtils.csv_to_stream()
      |> Geolite2City.import_from_stream(
        "GeoLite2-City-Blocks-IPv6.csv",
        sha: "some-sha",
        ts: "20231024"
      )

      imp = hd(DataImport.get_all_geolite2_imports())
      assert imp.import_file == "GeoLite2-City-Blocks-IPv6.csv"
      assert imp.import_sha256 == "some-sha"
      assert imp.timestamp == "20231024"
      assert imp.success_count == 0
      assert imp.error_count == 1
    end

    ###########################################################
    # import_from_stream/3 GeoLite2-City-Locations-en.csv tests
    ###########################################################
    test "import_from_stream/3 for GeoLite2-City-Locations-en.csv with all valid rows" do
      csv = """
      geoname_id,locale_code,continent_code,continent_name,country_iso_code,country_name,subdivision_1_iso_code,subdivision_1_name,subdivision_2_iso_code,subdivision_2_name,city_name,metro_code,time_zone,is_in_european_union
      3186367,es,EU,Europa,HR,Croacia,18,Istria,,,,,Europe/Zagreb,1
      """

      csv
      |> TestUtils.csv_to_stream()
      |> Geolite2City.import_from_stream(
        "GeoLite2-City-Locations-en.csv",
        sha: "some-sha",
        ts: "20231024"
      )

      {:ok, loc} = Geolite2City.get_location(3_186_367)
      assert loc.geoname_id == 3_186_367
      assert loc.locale_code == "es"
      assert loc.continent_code == "EU"
      assert loc.continent_name == "Europa"
      assert loc.country_iso_code == "HR"
      assert loc.country_name == "Croacia"
      assert loc.subdivision_1_iso_code == "18"
      assert loc.subdivision_1_name == "Istria"
      assert loc.subdivision_2_iso_code == nil
      assert loc.subdivision_2_name == nil
      assert loc.city_name == nil
      assert loc.metro_code == nil
      assert loc.time_zone == "Europe/Zagreb"
      assert loc.is_in_european_union == true

      imp = hd(DataImport.get_all_geolite2_imports())
      assert imp.import_file == "GeoLite2-City-Locations-en.csv"
      assert imp.import_sha256 == "some-sha"
      assert imp.timestamp == "20231024"
      assert imp.success_count == 1
      assert imp.error_count == 0
    end

    test "import_locations_from_stream/1 for GeoLite2-City-Locations-en.csv badly formatted input" do
      csv = """
      geoname_id,locale_code,continent_code,continent_name,country_iso_code,country_name,subdivision_1_iso_code,subdivision_1_name,subdivision_2_iso_code,subdivision_2_name,city_name,metro_code,time_zone,is_in_european_union
      3186367,badcode,EURO,Europa,HR,Croacia,18,Istria,,,,,Europe/Zagreb,1
      """

      csv
      |> TestUtils.csv_to_stream()
      |> Geolite2City.import_from_stream(
        "GeoLite2-City-Locations-en.csv",
        sha: "some-sha",
        ts: "20231024"
      )

      imp = hd(DataImport.get_all_geolite2_imports())
      assert imp.import_file == "GeoLite2-City-Locations-en.csv"
      assert imp.import_sha256 == "some-sha"
      assert imp.timestamp == "20231024"
      assert imp.success_count == 0
      assert imp.error_count == 1
    end
  end
end
