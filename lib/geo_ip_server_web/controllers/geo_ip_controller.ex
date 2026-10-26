defmodule GeoIpServerWeb.GeoIpController do
  @moduledoc """
  Provides a REST API for geolocation-related tasks.
  """

  use GeoIpServerWeb, :controller

  alias GeoIpServer.Geolite2City

  action_fallback GeoIpServerWeb.FallbackController

  @doc """
  The show method returns geolocation data for a provided ip address.

  ## Parameters
    - id: IP address in IPv4 or IPv6 dotted notation.

  ## Examples
      $ curl "http://localhost:4000/geoips/94.253.179.145"
      {"records":[{"city_name":"Zagreb","continent_code":"EU","continent_name":"Europe",...}]}

      $ curl "http://localhost:4000/geoips/10.0.0.1"
      {"error":"Not Found"}
  """
  def show(conn, %{"id" => ip_address}) do
    with {:ok, records} <- Geolite2City.get_locations_for_ip(ip_address) do
      json(conn, %{records: records})
    end
  end
end
