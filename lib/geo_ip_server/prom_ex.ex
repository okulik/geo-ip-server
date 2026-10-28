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

  @impl true
  def dashboard_assigns do
    [
      # Matches the uid of the Grafana data source in monitoring/grafana/provisioning.
      datasource_id: "victoriametrics",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards do
    [
      {:prom_ex, "beam.json"},
      {:prom_ex, "ecto.json"},
      {:prom_ex, "phoenix.json"}
    ]
  end
end
