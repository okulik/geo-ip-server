defmodule GeoIpServer.Cache do
  @moduledoc """
    The cache context.
  """
  use Nebulex.Cache,
    otp_app: :geo_ip_server,
    adapter: Nebulex.Adapters.Local

  @doc """
    Fetches an entry from a cache, generating a value on cache miss. If the entry
    requested is found in the cache, this function will operate in the same way as
    get/2. If the entry is not found in the cache, the provided fallback function
    will be executed.
  """
  def fetch(key, fallback) do
    {_, new} =
      get_and_update(key, fn val ->
        if val == nil do
          {nil, fallback.(key)}
        else
          {nil, val}
        end
      end)

    new
  end
end
