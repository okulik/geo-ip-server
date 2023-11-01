import Config

config :geo_ip_server, GeoIpServer.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "geo_ip_server_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :geo_ip_server, GeoIpServerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false

# Set up basic authentication credentials
config :geo_ip_server, GeoIpServerWeb.ApiAuthentication,
  username: System.get_env("API_BASIC_AUTH_USERNAME", "admin"),
  password: System.get_env("API_BASIC_AUTH_PASSWORD", "admin")

config :geo_ip_server, GeoIpServerWeb.AdminAuthentication,
  username: System.get_env("ADMIN_BASIC_AUTH_USERNAME", "admin"),
  password: System.get_env("ADMIN_BASIC_AUTH_PASSWORD", "admin")

config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
