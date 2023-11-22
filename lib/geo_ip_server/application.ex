defmodule GeoIpServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts the Nebulex based cache
      GeoIpServer.Cache,
      # Start the Ecto repository
      GeoIpServer.Repo,
      # Start the Endpoint (http/https)
      GeoIpServerWeb.Endpoint,
      # Start the PromEx metrics exporter
      GeoIpServer.PromEx
    ]

    opts = [strategy: :one_for_one, name: GeoIpServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GeoIpServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
