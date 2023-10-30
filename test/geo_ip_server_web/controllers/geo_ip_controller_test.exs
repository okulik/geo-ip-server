defmodule GeoIpServerWeb.GeoIpControllerTest do
  use GeoIpServerWeb.ConnCase

  alias GeoIpServer.Geolite2CityFixtures

  setup %{conn: conn} do
    {:ok,
     conn:
       conn
       |> put_req_header("accept", "application/json")}
  end

  describe "show with authorised user" do
    setup %{conn: conn} do
      {:ok,
       conn:
         conn
         |> put_req_header("authorization", get_basic_auth_token())}
    end

    test "renders a location", %{conn: conn} do
      loc = Geolite2CityFixtures.location_fixture()

      Geolite2CityFixtures.block_ipv4_fixture(%{
        network: "1.0.77.0/24",
        geoname_id: loc.geoname_id
      })

      resp =
        conn
        |> get(~p"/geoips/1.0.77.0")
        |> json_response(200)
        |> Map.fetch!("records")
        |> hd()

      assert %{
               "city_name" => "Zagreb",
               "continent_code" => "EU",
               "continent_name" => "Europe"
             } = resp
    end

    test "renders bad request when ip address is misformatted", %{conn: conn} do
      resp =
        conn
        |> get(~p"/geoips/notaddr")
        |> json_response(400)

      assert %{"error" => "Bad Request"} = resp
    end

    test "renders not found when ip address can't be found", %{conn: conn} do
      resp =
        conn
        |> get(~p"/geoips/10.0.0.1")
        |> json_response(404)

      assert %{"error" => "Not Found"} = resp
    end
  end

  describe "show with unauthorised user" do
    test "returns unauthorised error", %{conn: conn} do
      loc = Geolite2CityFixtures.location_fixture()

      Geolite2CityFixtures.block_ipv4_fixture(%{
        network: "1.0.77.0/24",
        geoname_id: loc.geoname_id
      })

      conn = get(conn, ~p"/geoips/1.0.77.0")
      assert response(conn, 401)
    end
  end

  defp get_basic_auth_token do
    username = Application.get_env(:geo_ip_server, GeoIpServerWeb.ApiAuthentication)[:username]
    password = Application.get_env(:geo_ip_server, GeoIpServerWeb.ApiAuthentication)[:password]
    "Basic " <> Base.encode64("#{username}:#{password}")
  end
end
