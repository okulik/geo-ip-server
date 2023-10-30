defmodule GeoIpServer.GeoDataTest.IPv4 do
  use GeoIpServer.DataCase

  import GeoIpServer.Geolite2CityFixtures

  alias GeoIpServer.Geolite2City
  alias GeoIpServer.Geolite2City.BlockIpv4

  describe "geolite city2 tests" do
    test "get_block_ipv4/1 returns the data for the existing range" do
      bip4 = block_ipv4_fixture()

      {:ok, block_ipv4} = Geolite2City.get_block_ipv4(bip4.network)

      assert block_ipv4.network == bip4.network
      assert block_ipv4.geoname_id == bip4.geoname_id
      assert block_ipv4.registered_country_geoname_id == bip4.registered_country_geoname_id
      assert block_ipv4.represented_country_geoname_id == bip4.represented_country_geoname_id
      assert block_ipv4.is_anonymous_proxy == bip4.is_anonymous_proxy
      assert block_ipv4.is_satellite_provider == bip4.is_satellite_provider
      assert block_ipv4.postal_code == bip4.postal_code
      assert block_ipv4.latitude == bip4.latitude
      assert block_ipv4.longitude == bip4.longitude
      assert block_ipv4.accuracy_radius == bip4.accuracy_radius
    end

    test "get_block_ipv4/1 returns error for a non-existing range" do
      assert Geolite2City.get_block_ipv4("10.0.0.0/8") == {:error, :not_found}
    end

    test "get_block_ipv4/1 returns error for an invalid range" do
      assert Geolite2City.get_block_ipv4("invalid.address") == {:error, :invalid_ip4r}
    end

    test "create_block_ipv4!/1 with valid attributes creates BlockIpv4 struct" do
      attrs = %{
        network: "10.0.0.0/8",
        geoname_id: 123,
        registered_country_geoname_id: 123,
        represented_country_geoname_id: 123,
        is_anonymous_proxy: false,
        is_satellite_provider: false,
        postal_code: "12345",
        latitude: 44.8217,
        longitude: 13.9369,
        accuracy_radius: 42,
        inserted_at: ~U[2023-10-08 02:00:00Z],
        updated_at: ~U[2023-10-08 02:00:00Z]
      }

      loc = Geolite2City.create_block_ipv4!(attrs)
      assert %BlockIpv4{} = loc
      {:ok, network} = EctoIPRange.IP4R.cast("10.0.0.0/8")
      assert loc.network == network
      assert loc.geoname_id == 123
      assert loc.registered_country_geoname_id == 123
    end

    test "create_block_ipv4!/1 with invalid data returns error" do
      assert_raise(Ecto.InvalidChangesetError, fn ->
        Geolite2City.create_block_ipv4!(%{})
      end)
    end
  end
end
