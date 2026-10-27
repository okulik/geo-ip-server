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
  Imports the GeoLite2 City data from temporary folder into a database.
  """
  def import_geolite2(tmp_dir) do
    load_app()
    # Start the application except the web server (as PHX_SERVER is only
    # set when the web server is started by running bin/server in production).
    {:ok, _} = Application.ensure_all_started(:geo_ip_server)

    # Import downloaded GeoLite2 City data into a database.
    stats = GeoIpServer.Geolite2City.import_geolite_files!(tmp_dir)

    # Push metrics to the Pushgateway (production only).
    case Application.fetch_env(@app, GeoIpServer.Pushgateway) do
      {:ok, cfg} -> Enum.each(stats, &push_csv_import_duration_metrics(&1, cfg[:port]))
      :error -> :ok
    end

    # Get the port from the PORT environment variable or default to 4000.
    port = String.to_integer(System.get_env("PORT") || "4000")

    # Delete the cache after a successful download.
    :hackney.delete("http://localhost:#{port}/admin/cache", [], "",
      basic_auth: {
        System.get_env("ADMIN_BASIC_AUTH_USERNAME"),
        System.get_env("ADMIN_BASIC_AUTH_PASSWORD")
      }
    )
  end

  defp push_csv_import_duration_metrics(stat, port) do
    :hackney.post(
      "http://localhost:#{port}/metrics/job/csv-import/instance/cronjob",
      [],
      csv_import_duration_metrics(stat.import_file, stat.running_time)
    )
  end

  defp csv_import_duration_metrics(import_file, running_time) do
    buckets =
      Enum.map(GeoIpServer.PromExPlugin.csv_import_duration_event_buckets(), fn bucket ->
        {bucket, if(running_time <= bucket, do: 1, else: 0)}
      end) ++ [{"+Inf", 1}]

    [
      """
      # HELP geo_ip_server_csv_import_duration The duration in milliseconds of CSV import.
      # TYPE geo_ip_server_csv_import_duration histogram
      geo_ip_server_csv_import_duration_sum{csv="#{import_file}"} #{running_time}
      geo_ip_server_csv_import_duration_count{csv="#{import_file}"} 1
      """
      | Enum.map(buckets, fn {le, count} ->
          ~s|geo_ip_server_csv_import_duration_bucket{csv="#{import_file}",le="#{le}"} #{count}\n|
        end)
    ]
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
