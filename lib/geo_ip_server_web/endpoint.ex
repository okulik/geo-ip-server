defmodule GeoIpServerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :geo_ip_server

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :geo_ip_server,
    gzip: false,
    only: GeoIpServerWeb.static_paths()
  )

  plug(PromEx.Plug, prom_ex_module: GeoIpServer.PromEx)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
    plug(Phoenix.Ecto.CheckRepoStatus, otp_app: :geo_ip_server)
  end

  plug(Plug.RequestId)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(GeoIpServerWeb.Router)
end
