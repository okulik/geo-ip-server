defmodule GeoIpServerWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use GeoIpServerWeb, :controller

  # Handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: GeoIpServerWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  # Handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: GeoIpServerWeb.ErrorJSON)
    |> render(:"404")
  end
end
