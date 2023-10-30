defmodule GeoIpServer.Repo do
  use Ecto.Repo,
    otp_app: :geo_ip_server,
    adapter: Ecto.Adapters.Postgres
end
