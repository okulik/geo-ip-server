defmodule GeoIpServer.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """

  require Logger

  @app :geo_ip_server

  @doc """
  Migrates the database.
  """
  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  @doc """
  Rolls back the database by one migration.
  """
  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Imports the latest GeoLite2 City data into a database.
  """
  def import_geolite2 do
    load_app()
    # Start the application except the web server (as PHX_SERVER is only
    # set when the web server is started by running bin/server in production).
    {:ok, _} = Application.ensure_all_started(:geo_ip_server)

    # Download and import the fresh copy of GeoLite2 City data.
    stats = GeoIpServer.Geolite2City.download_and_import_geolite_files!()

    # Push metrics to the Pushgateway (production only).
    cfg = Application.get_env(:geo_ip_server, GeoIpServer.Pushgateway)

    if cfg != nil do
      Enum.each(stats, fn stat ->
        :hackney.post(
          "http://localhost:#{cfg[:port]}/metrics/job/csv-import/instance/cronjob",
          [],
          """
          # HELP geo_ip_server_csv_import_duration The duration in milliseconds of CSV import.
          # TYPE geo_ip_server_csv_import_duration histogram
          geo_ip_server_csv_import_duration{csv="#{stat.import_file}"} #{stat.running_time}
          """
        )
      end)
    end

    # Get the port from the PORT environment variable or default to 4000.
    port = String.to_integer(System.get_env("PORT") || "4000")

    # Delete the cache after a successful download.
    :hackney.delete(~c"http://localhost:#{port}/admin/cache", [],
      basic_auth: {
        to_charlist(System.get_env("ADMIN_BASIC_AUTH_USERNAME")),
        to_charlist(System.get_env("ADMIN_BASIC_AUTH_PASSWORD"))
      }
    )
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
