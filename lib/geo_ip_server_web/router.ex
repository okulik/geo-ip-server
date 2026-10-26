defmodule GeoIpServerWeb.Router do
  use GeoIpServerWeb, :router

  pipeline :api do
    plug(:basic_auth, GeoIpServerWeb.ApiAuthentication)
    plug(:accepts, ["json"])
  end

  pipeline :admin do
    plug(:basic_auth, GeoIpServerWeb.AdminAuthentication)
    plug(:accepts, ["json"])
  end

  scope "/", GeoIpServerWeb do
    pipe_through(:api)

    get("/geoips/:id", GeoIpController, :show)
  end

  scope "/admin", GeoIpServerWeb do
    pipe_through(:admin)

    delete("/cache", AdminCacheController, :delete)
  end

  defp basic_auth(conn, config_key) do
    config = Application.fetch_env!(:geo_ip_server, config_key)

    Plug.BasicAuth.basic_auth(conn,
      username: Keyword.fetch!(config, :username),
      password: Keyword.fetch!(config, :password)
    )
  end
end
