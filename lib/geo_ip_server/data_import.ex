defmodule GeoIpServer.DataImport do
  @moduledoc """
    The DataImport context.
  """

  alias GeoIpServer.DataImport.Geolite2Import
  alias GeoIpServer.Repo

  require Logger

  @doc """
    Returns a single import.

    ## Examples

        iex> get_import(1)
        %Geolite2Import{}

        iex> get_import(999)
        nil
  """
  def get_geolite2_import(id) do
    Repo.get(Geolite2Import, id)
  end

  @doc """
    Returns all imports.

    ## Examples

        iex> get_all_imports()
        [%Geolite2Import{}, %Geolite2Import{}]
  """
  def get_all_geolite2_imports do
    Repo.all(Geolite2Import)
  end

  @doc """
    Writes a single import.

    ## Examples

        iex> create_import!(%{import_file: "foo.csv", import_sha256: "123", \
          timestamp: "20231024", success_count: 100, error_count: 0, \
          running_time: 1000, created_at: ~U[2023-10-27 10:34:00Z]})
        %Geolite2Import{}

        iex> create_import(%{import_file: "foo.csv")
        ** (Ecto.InvalidChangesetError)
  """
  def create_geolite2_import!(attrs) do
    %Geolite2Import{}
    |> Geolite2Import.changeset(attrs)
    |> Repo.insert!()
  end
end
