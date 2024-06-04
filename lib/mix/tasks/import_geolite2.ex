defmodule Mix.Tasks.ImportGeolite2 do
  @moduledoc """
  The `mix import_geolite2` task downloads and imports ip addresses
  from the CSV files archive.
  """
  @shortdoc "Imports ip addresses from MaxMind's Geolite2 City CSV database"

  use Mix.Task

  alias GeoIpServer.Release

  @doc """
  Downloads and imports ip addresses from the CSV files archive.
  """
  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {tmp_dir} =
      Enum.take(args, 1)
      |> List.to_tuple()

    Release.import_geolite2(tmp_dir)
  end
end
