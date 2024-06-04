import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/geo_ip_server start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :geo_ip_server, GeoIpServerWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing
      For example: postgres://postgres:PASS@geo-ip-server-db.internal/geo-ip-srv-prod
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :geo_ip_server, GeoIpServer.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :geo_ip_server, GeoIpServerWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ]

  # Configure basic authentication credentials.
  config :geo_ip_server, GeoIpServerWeb.ApiAuthentication,
    username:
      System.get_env("API_BASIC_AUTH_USERNAME") ||
        raise("environment variable API_BASIC_AUTH_USERNAME is missing"),
    password:
      System.get_env("API_BASIC_AUTH_PASSWORD") ||
        raise("environment variable API_BASIC_AUTH_PASSWORD is missing")

  config :geo_ip_server, GeoIpServerWeb.AdminAuthentication,
    username:
      System.get_env("ADMIN_BASIC_AUTH_USERNAME") ||
        raise("environment variable ADMIN_BASIC_AUTH_USERNAME is missing"),
    password:
      System.get_env("ADMIN_BASIC_AUTH_PASSWORD") ||
        raise("environment variable ADMIN_BASIC_AUTH_PASSWORD is missing")

  config :geo_ip_server, GeoIpServer.Pushgateway,
    port: String.to_integer(System.get_env("PUSHGATEWAY_PORT", "9091"))
end
