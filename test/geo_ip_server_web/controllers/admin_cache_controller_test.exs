defmodule GeoIpServerWeb.AdminCacheControllerTest do
  use GeoIpServerWeb.ConnCase

  alias GeoIpServer.Geolite2City
  alias GeoIpServer.Geolite2CityFixtures

  setup %{conn: conn} do
    {:ok,
     conn:
       conn
       |> put_req_header("accept", "application/json")}
  end

  describe "delete with authorised user" do
    setup %{conn: conn} do
      {:ok,
       conn:
         conn
         |> put_req_header("authorization", get_basic_auth_token())}
    end

    test "deletes all cache entries", %{conn: conn} do
      loc = Geolite2CityFixtures.location_fixture()

      Geolite2CityFixtures.block_ipv4_fixture(%{
        network: "10.0.0.0/8",
        geoname_id: loc.geoname_id
      })

      # This will force the cache to be populated.
      {:ok, _} = Geolite2City.get_locations_for_ip("10.0.0.0")

      resp =
        conn
        |> delete(~p"/admin/cache")

      %{"items_deleted" => items_deleted} = json_response(resp, 200)

      assert items_deleted > 0
    end
  end

  describe "delete with unauthorised user" do
    test "returns unauthorised error", %{conn: conn} do
      resp =
        conn
        |> delete(~p"/admin/cache")

      assert response(resp, 401)
    end
  end

  defp get_basic_auth_token do
    username = Application.get_env(:geo_ip_server, GeoIpServerWeb.AdminAuthentication)[:username]
    password = Application.get_env(:geo_ip_server, GeoIpServerWeb.AdminAuthentication)[:password]
    "Basic " <> Base.encode64("#{username}:#{password}")
  end
end
