defmodule GeoIpServerWeb.AdminCacheController do
  @moduledoc """
  Provides a REST API for admin cache tasks.
  """

  use GeoIpServerWeb, :controller

  alias GeoIpServer.Cache

  action_fallback(GeoIpServerWeb.FallbackController)

  @doc """
  The delete method purges the whole cache.

  ## Examples
      $ curl -i -X DELETE "http://localhost:4000/admin/cache"
      {"items_deleted": 100}
  """
  def delete(conn, _) do
    items_deleted = Cache.delete_all()

    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(200, Jason.encode!(%{items_deleted: items_deleted}))
  end
end
