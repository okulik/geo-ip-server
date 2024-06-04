import Config

config :geo_ip_server, GeoIpServer.Repo,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "localhost"),
  database: System.get_env("PGDATABASE", "geo_ip_server_dev"),
  port: System.get_env("PGPORT", "5432"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  log: :debug

# For development, we disable any cache and enable
# debugging and code reloading.
config :geo_ip_server, GeoIpServerWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4000")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  watchers: []

# Set up basic authentication credentials
config :geo_ip_server, GeoIpServerWeb.ApiAuthentication,
  username: System.get_env("API_BASIC_AUTH_USERNAME", "admin"),
  password: System.get_env("API_BASIC_AUTH_PASSWORD", "admin")

config :geo_ip_server, GeoIpServerWeb.AdminAuthentication,
  username: System.get_env("ADMIN_BASIC_AUTH_USERNAME", "admin"),
  password: System.get_env("ADMIN_BASIC_AUTH_PASSWORD", "admin")

# Do not include metadata nor timestamps in development logs
config :logger, :console,
  format: "[$level] $message\n",
  level: :debug

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
