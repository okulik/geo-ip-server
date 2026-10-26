import Config

# Configures the nebulex cache
config :geo_ip_server, GeoIpServer.Cache,
  backend: :shards,
  gc_interval: :timer.hours(2),
  max_size: 100_000,
  allocated_memory: 104_857_600,
  gc_memory_check_interval: :timer.seconds(10)

config :geo_ip_server,
  ecto_repos: [GeoIpServer.Repo]

# Configures the endpoint
config :geo_ip_server, GeoIpServerWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: GeoIpServerWeb.ErrorJSON],
    layout: false
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :sentry,
  environment_name: config_env(),
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()]

import_config "#{config_env()}.exs"
