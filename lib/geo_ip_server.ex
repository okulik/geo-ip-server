defmodule GeoIpServer do
  @moduledoc """
  Documentation for `GeoIpServer`.
  """

  alias Ecto.Adapters.Postgres

  Postgrex.Types.define(
    GeoIpServer.PostgrexTypes,
    EctoIPRange.Postgrex.extensions() ++ Postgres.extensions()
  )
end
