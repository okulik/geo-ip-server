defmodule GeoIpServer.GeoDataTest.IPv6 do
  use GeoIpServer.DataCase

  import GeoIpServer.Geolite2CityFixtures

  alias GeoIpServer.Geolite2City
  alias GeoIpServer.Geolite2City.BlockIpv6

  describe "geolite city2 tests" do
    test "get_block_ipv6/1 returns the data for the existing range" do
      bip6 = block_ipv6_fixture()

      {:ok, block_ipv6} = Geolite2City.get_block_ipv6(bip6.network)
      assert %BlockIpv6{} = block_ipv6
      assert block_ipv6.network == bip6.network
      assert block_ipv6.geoname_id == bip6.geoname_id
      assert block_ipv6.registered_country_geoname_id == bip6.registered_country_geoname_id
      assert block_ipv6.represented_country_geoname_id == bip6.represented_country_geoname_id
      assert block_ipv6.is_anonymous_proxy == bip6.is_anonymous_proxy
      assert block_ipv6.is_satellite_provider == bip6.is_satellite_provider
      assert block_ipv6.postal_code == bip6.postal_code
      assert block_ipv6.latitude == bip6.latitude
      assert block_ipv6.longitude == bip6.longitude
      assert block_ipv6.accuracy_radius == bip6.accuracy_radius
    end

    test "get_block_ipv6/1 returns error for a non-existing range" do
      assert Geolite2City.get_block_ipv6("2001:218:c000::/50") == {:error, :not_found}
    end

    test "get_block_ipv6/1 returns error for an invalid range" do
      assert Geolite2City.get_block_ipv6("invalid.address") == {:error, :invalid_ip}
    end

    test "create_block_ipv6!/1 with valid attributes creates BlockIpv6 struct" do
      attrs = %{
        network: "2001:218:c000::/50",
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

      loc = Geolite2City.create_block_ipv6!(attrs)
      assert %BlockIpv6{} = loc
      {:ok, network} = EctoNetwork.CIDR.cast("2001:218:c000::/50")
      assert loc.network == network
      assert loc.geoname_id == 123
      assert loc.registered_country_geoname_id == 123
    end

    test "create_block_ipv6!/1 with invalid data returns error" do
      assert_raise(Ecto.InvalidChangesetError, fn ->
        Geolite2City.create_block_ipv6!(%{})
      end)
    end
  end
end
