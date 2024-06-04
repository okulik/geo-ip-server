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
    cfg = Application.get_env(:geo_ip_server, GeoIpServer.Pushgateway)

    if cfg != nil do
      Enum.each(stats, fn stat ->
        :hackney.post(
          "http://localhost:#{cfg[:port]}/metrics/job/csv-import/instance/cronjob",
          [],
          print_csv_import_duration_event_metrics(stat.import_file, stat.running_time)
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

  defp print_csv_import_duration_event_metrics(import_file, running_time) do
    buckets = assign_csv_import_duration_event_buckets(running_time)

    text = """
      # HELP geo_ip_server_csv_import_duration The duration in milliseconds of CSV import.
      # TYPE geo_ip_server_csv_import_duration histogram
      geo_ip_server_csv_import_duration_sum{csv="#{import_file}"} #{running_time}
      geo_ip_server_csv_import_duration_count{csv="#{import_file}"} 1
    """

    Enum.reduce(buckets, text, fn {bucket, val}, acc ->
      acc <>
        """
          geo_ip_server_csv_import_duration_bucket{csv="#{import_file}",le="#{bucket}"} #{val}
        """
    end)
  end

  defp assign_csv_import_duration_event_buckets(val) do
    buckets = GeoIpServer.PromExPlugin.csv_import_duration_event_buckets()

    Enum.reduce(buckets, %{}, fn bucket, acc ->
      Map.put(acc, to_string(bucket), if(val <= bucket, do: 1, else: 0))
    end)
    |> Map.put("+Inf", 1)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
