defmodule Mix.Tasks.ImportGeolite2 do
  @moduledoc """
  The `mix import_geolite2` task downloads and imports ip addresses
  from the CSV files archive.
  """

  use Mix.Task

  alias GeoIpServer.Release

  @doc """
  Downloads and imports ip addresses from the CSV files archive.
  """
  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    Release.import_geolite2db()
  end
end
