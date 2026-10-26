defmodule GeoIpServer.Cache do
  @moduledoc """
  The cache context.
  """
  use Nebulex.Cache,
    otp_app: :geo_ip_server,
    adapter: Nebulex.Adapters.Local
end
