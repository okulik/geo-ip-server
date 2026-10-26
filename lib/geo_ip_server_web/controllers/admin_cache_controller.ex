defmodule GeoIpServerWeb.AdminCacheController do
  @moduledoc """
  Provides a REST API for admin cache tasks.
  """

  use GeoIpServerWeb, :controller

  alias GeoIpServer.Cache

  @doc """
  The delete method purges the whole cache.

  ## Examples
      $ curl -i -X DELETE "http://localhost:4000/admin/cache"
      {"items_deleted": 100}
  """
  def delete(conn, _) do
    json(conn, %{items_deleted: Cache.delete_all!()})
  end
end
