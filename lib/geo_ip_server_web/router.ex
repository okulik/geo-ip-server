defmodule GeoIpServerWeb.Router do
  use GeoIpServerWeb, :router

  pipeline :api do
    plug(:api_auth)
    plug(:accepts, ["json"])

    plug(Plug.Parsers,
      parsers: [:urlencoded, :json],
      json_decoder: Jason
    )
  end

  pipeline :admin do
    plug(:admin_auth)
    plug(:accepts, ["json"])

    plug(Plug.Parsers,
      parsers: [:urlencoded, :json],
      json_decoder: Jason
    )
  end

  scope "/", GeoIpServerWeb do
    pipe_through(:api)

    get("/geoips/:id", GeoIpController, :show)
  end

  scope "/admin", GeoIpServerWeb do
    pipe_through(:admin)

    delete("/cache", AdminCacheController, :delete)
  end

  defp api_auth(conn, _opts) do
    username = Application.get_env(:geo_ip_server, GeoIpServerWeb.ApiAuthentication)[:username]
    password = Application.get_env(:geo_ip_server, GeoIpServerWeb.ApiAuthentication)[:password]
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end

  defp admin_auth(conn, _opts) do
    username = Application.get_env(:geo_ip_server, GeoIpServerWeb.AdminAuthentication)[:username]
    password = Application.get_env(:geo_ip_server, GeoIpServerWeb.AdminAuthentication)[:password]
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end
end
