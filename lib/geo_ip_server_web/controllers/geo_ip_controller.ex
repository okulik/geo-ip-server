defmodule GeoIpServerWeb.GeoIpController do
  @moduledoc """
  Provides a REST API for geolocation-related tasks.
  """

  use GeoIpServerWeb, :controller

  alias GeoIpServer.Geolite2City

  action_fallback(GeoIpServerWeb.FallbackController)

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
  def show(conn, _params) do
    with {:ok, ip_address} <- validate_params(conn),
         {:ok, records} when records != [] <- Geolite2City.get_locations_for_ip(ip_address) do
      conn
      |> put_resp_header("content-type", "application/json; charset=utf-8")
      |> send_resp(200, Jason.encode!(%{records: records}))
    else
      {:ok, []} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: GeoIpServerWeb.ErrorJSON)
        |> render(:"404")

      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> put_view(json: GeoIpServerWeb.ErrorJSON)
        |> render(:"400")

      {:error, code, message} ->
        conn
        |> put_status(code)
        |> put_view(json: GeoIpServerWeb.ErrorJSON)
        |> render(:"#{code}", message: message)
    end
  end

  defp validate_params(conn) do
    case Map.fetch(conn.params, "id") do
      {:ok, id} ->
        {:ok, id}

      :error ->
        {:error, 400, "missing IP address"}
    end
  end
end
