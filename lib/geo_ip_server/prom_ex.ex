defmodule GeoIpServer.PromEx do
  @moduledoc """
  Used for exporting different types of metrics to Prometheus.
  """

  use PromEx, otp_app: :geo_ip_server

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      Plugins.Beam,
      Plugins.Ecto,
      {Plugins.Phoenix, router: GeoIpServerWeb.Router, endpoint: GeoIpServerWeb.Endpoint},
      GeoIpServer.PromExPlugin
    ]
  end
end
