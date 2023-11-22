defmodule GeoIpServer.Geolite2City do
  @moduledoc """
  The Geolite2City context.
  """

  import GeoIpServer.Utils, only: [struct_from_sql_query_result: 2, map_from_sql_query_result: 1]

  alias GeoIpServer.Cache
  alias GeoIpServer.DataImport
  alias GeoIpServer.Downloader
  alias GeoIpServer.Geolite2City.{BlockIpv4, BlockIpv6, Location}
  alias GeoIpServer.Repo
  alias NimbleCSV.RFC4180, as: CSV

  require Logger

  @locations "GeoLite2-City-Locations-en.csv"
  @blocks_ipv4 "GeoLite2-City-Blocks-IPv4.csv"
  @blocks_ipv6 "GeoLite2-City-Blocks-IPv6.csv"
  @zip_folder_prefix "GeoLite2-City-CSV_"

  @unzip_file_list [
    @locations,
    @blocks_ipv4,
    @blocks_ipv6
  ]

  @random_file_name_length 10
  @csv_batch_size 1000

  @doc """
    Returns a {:ok, %BlockIpv4{}} tuple for a provided IPv4 CIDR formated
    cidr argument. If the BlockIpv4 does not exist, an {:error, :not_found}
    tuple is returned. If cidr is invalid, an {:error, :invalid_range}
    tuple is returned.

    ## Examples

        iex> GeoIpServer.Geolite2City.get_block_ipv4("1.2.237.0/10")
        {:ok, %GeoIpServer.Geolite2City.BlockIpv4{
          network: #EctoNetwork.CIDR<...
          geoname_id: 1151254,
          ...

        iex> GeoIpServer.Geolite2City.get_block_ipv4("10.0.0.0/8")
        {:error, :not_found}

        iex> GeoIpServer.Geolite2City.get_block_ipv4("bad-cider")
        {:error, :invalid_range}

  """
  def get_block_ipv4(cidr), do: get_block_ip(cidr, type: :ip4)

  @doc """
    Creates a BlockIpv4.

    ## Examples

        iex> create_block_ipv4!(%{field: value})
        %BlockIpv4{}

        iex> create_block_ipv4!(%{field: bad_value})
        ** (Ecto.InvalidChangesetError)
  """
  def create_block_ipv4!(attrs \\ %{}) do
    %BlockIpv4{}
    |> BlockIpv4.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
    Returns a {:ok, %BlockIpv6{}} tuple for a provided IPv6 CIDR formated
    cidr argument. If the BlockIpv6 does not exist, an {:error, :not_found}
    tuple is returned. If cidr is invalid, an {:error, :invalid_ip6r}
    tuple is returned.

    ## Examples

        iex> GeoIpServer.Geolite2City.get_block_ipv6("1999:123:4567::/51")
        {:ok, %GeoIpServer.Geolite2City.BlockIpv6{
          network: #EctoNetwork.CIDR<...
          geoname_id: 1151254,
          ...

        iex> GeoIpServer.Geolite2City.get_block_ipv6("fc00::/7")
        {:error, :not_found}

        iex> GeoIpServer.Geolite2City.get_block_ipv6("bad-cider")
        {:error, :invalid_range}
  """
  def get_block_ipv6(cidr), do: get_block_ip(cidr, type: :ip6)

  @doc """
    Creates a BlockIpv6.

    ## Examples

        iex> create_block_ipv6!(%{network: "1999:123:4567::/51", geoname_id: 1151254, ...})
        %BlockIpv6{}

        iex> create_block_ipv6!(%{})
        ** (Ecto.InvalidChangesetError)
  """
  def create_block_ipv6!(attrs \\ %{}) do
    %BlockIpv6{}
    |> BlockIpv6.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
    Returns a {:ok, %Location{}} tuple for a provided geoname_id. If the
    Location does not exist, an {:error, :not_found} tuple is returned.

    ## Examples

        iex> GeoIpServer.Geolite2City.get_location(1151254)
        {:ok, %GeoIpServer.Geolite2City.Location{
          geoname_id: 1151254,
          locale_code: "en",
          continent_code: "EU",
          continent_name: "Europe",
          country_iso_code: "HR",
          ...

        iex> GeoIpServer.Geolite2City.get_location(9999999)
        {:error, :not_found}
  """
  def get_location(geoname_id) do
    case Repo.get(Location, geoname_id) do
      loc = %Location{} -> {:ok, loc}
      nil -> {:error, :not_found}
    end
  end

  @doc """
    Creates a Location.

    ## Examples

        iex> create_location!(%{geoname_id: 1151254, locale_code: "en", ...})
        %Location{}

        iex> create_location!(%{})
        ** (Ecto.InvalidChangesetError)
  """
  def create_location!(attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
    Returns geolocation data for a provided ip address. IP address can be provided
    in either IPv4 or IPv6 formats and is searched accordingly as we store these
    IP addresses in separate tables. If the ip address is not found in
    either tables, {:error, :not_found} tuple is returned. If ip_address is invalid,
    {:error, :invalid_ip} is returned.

    ## Examples

        iex> GeoIpServer.Geolite2City.get_locations_for_ip("1.2.237.0")
        {:ok,
         [
           %{
             "city_name" => "Chiang Mai",
             "continent_code" => "AS",
             "continent_name" => "Asia",
             ...
           }
         ]}

        iex> GeoIpServer.Geolite2City.get_locations_for_ip("10.0.0.0")
        {:error, :not_found}

        iex> GeoIpServer.Geolite2City.get_locations_for_ip("bad-addr")
        {:error, :invalid_ip}

  """
  def get_locations_for_ip(ip_address) do
    case get_locations_for_ip(ip_address, type: :ip4) do
      {:error, :invalid_ip} -> get_locations_for_ip(ip_address, type: :ip6)
      ret -> ret
    end
  end

  @doc """
    Downloads the Geolite2 City database files, validates the sha256 of the
    downloaded zip file, extracts the required files from the zip file, and
    imports the extracted files into the database. This function is typically
    called from a CRON job, or from a mix task.
    Returns a list of Geolite2Import structs, one for each imported file.
    Locations are imported first, followed by BlockIpv4, and then BlockIpv6.
    Each file is saved to a separate table in the database.

    ## Examples

        iex> download_and_import_geolite_files!()
        [
          %Geolite2Import{
            import_file: "GeoLite2-City-Locations-en.csv",
            import_file_sha256: "abcd1234",
            success_count: 10,
            error_count: 0,
            running_time: 12
          },
          %Geolite2Import{
            import_file: "GeoLite2-City-Blocks-IPv4.csv",
            import_file_sha256: "abcd9876",
            success_count: 5,
            error_count: 1,
            running_time: 234
          },
          %Geolite2Import{
            import_file: "GeoLite2-City-Blocks-IPv6.csv",
            import_file_sha256: "zyxw4321",
            success_count: 333,
            error_count: 12,
            running_time: 123
          }
        ]
  """
  def download_and_import_geolite_files! do
    # Create a temporary directory for the downloaded files.
    temp_dir = Path.join([System.tmp_dir!(), Downloader.random_string(@random_file_name_length)])
    File.mkdir_p!(temp_dir)

    # Download the zip file and the sha256 file into the temporary directory.
    geolite_sha256_name = Downloader.download_from_url(download_url_sha256(), temp_dir)
    geolite_zip_name = Downloader.download_from_url(download_url(), temp_dir)

    # Get the full path to the downloaded files.
    geolite_sha256_path = Path.join([temp_dir, geolite_sha256_name])
    geolite_zip_path = Path.join([temp_dir, geolite_zip_name])

    try do
      # Validate the sha256 of the downloaded geoip zip file.
      import_sha256 = validate_sha256!(geolite_sha256_path, geolite_zip_path)

      # Extracted basename of the zip file without the extension (e.g. GeoLite2-City-CSV_20232310).
      zip_folder = Path.basename(geolite_zip_name, ".zip")

      # Extract only required files from the zip file.
      file_list =
        case :zip.unzip(String.to_charlist(geolite_zip_path), [
               {:file_list, unzip_file_list(zip_folder)},
               {:cwd, String.to_charlist(temp_dir)}
             ]) do
          {:ok, file_list} ->
            file_list

          _ ->
            raise "failed to unzip #{geolite_zip_path}"
        end

      # Extract the timestamp from the zip folder name (e.g. 20232310).
      @zip_folder_prefix <> ts = zip_folder

      stats =
        file_list
        |> Enum.map(fn file_name -> Path.basename(file_name) end)
        |> Enum.map(fn file_name ->
          import_csv_file!(temp_dir, zip_folder, file_name,
            sha: import_sha256,
            ts: ts
          )
        end)

      stats
    after
      File.rm_rf!(temp_dir)
    end
  end

  @doc """
    Imports the provided CSV file into the database. The CSV file is expected
    to be in the temporary directory. The CSV file is imported in batches of
    @csv_batch_size rows. Each batch is imported in a transaction.
    Returns a Geolite2Import struct.

    ## Examples

        iex> import_csv_file!(temp_dir, zip_folder, csv)
        %Geolite2Import{
          import_file: "GeoLite2-City-Locations-en.csv",
          import_file_sha256: "abcd1234",
          success_count: 10,
          error_count: 0,
          running_time: 12
        }
  """
  def import_csv_file!(temp_dir, zip_folder, csv, sha: import_sha256, ts: ts) do
    Path.join([temp_dir, zip_folder, csv])
    |> File.stream!()
    |> import_from_stream(csv, sha: import_sha256, ts: ts)
  end

  def import_from_stream(file_stream, csv, sha: import_sha256, ts: ts) do
    stats_table = :ets.new(:csv_import_stats, [:set, :private])

    try do
      :ets.insert(stats_table, {:success_count, 0})
      :ets.insert(stats_table, {:error_count, 0})

      import_with_tx(file_stream, stats_table, csv, sha: import_sha256, ts: ts)
    after
      :ets.delete(stats_table)
    end
  end

  defp import_with_tx(file_stream, stats_table, csv, sha: import_sha256, ts: ts) do
    t0 = System.monotonic_time(:millisecond)

    res =
      Repo.transaction(
        fn ->
          now = DateTime.utc_now()

          file_stream
          |> CSV.parse_stream(skip_headers: true)
          |> Stream.chunk_every(@csv_batch_size)
          |> Stream.each(fn chunk ->
            chunk
            |> Enum.map(&convert_row_to_changeset(&1, now, csv))
            |> write_changesets_to_db(csv)
            |> update_stats(stats_table)
          end)
          |> Stream.run()

          t1 = System.monotonic_time(:millisecond)

          success_count = elem(hd(:ets.lookup(stats_table, :success_count)), 1)
          error_count = elem(hd(:ets.lookup(stats_table, :error_count)), 1)

          :telemetry.execute(
            [:geo_ip_server, :csv_import, :duration],
            %{took: t1 - t0},
            %{
              csv: csv
            }
          )

          DataImport.create_geolite2_import!(%{
            import_file: csv,
            import_sha256: import_sha256,
            success_count: success_count,
            error_count: error_count,
            running_time: t1 - t0,
            created_at: now,
            timestamp: ts
          })
        end,
        timeout: :infinity
      )

    case res do
      {:ok, val} -> val
      {:error, reason} -> raise "error importing CSV: #{inspect(reason)}"
    end
  end

  defp write_changesets_to_db(changesets, csv) do
    {ok_changesets, changesets} =
      Enum.reduce(changesets, {[], []}, fn cs, {oks, all} ->
        if cs.valid? do
          {[cs.changes | oks], [cs | all]}
        else
          log_invalid_changeset(cs, csv)
          {oks, [cs | all]}
        end
      end)

    insert_to_db(ok_changesets, csv)

    changesets
  end

  defp update_stats(changesets, stats_table) do
    {success_count, error_count} =
      Enum.reduce(changesets, {0, 0}, fn cs, {s, e} ->
        if cs.valid? do
          {s + 1, e}
        else
          {s, e + 1}
        end
      end)

    :ets.update_counter(stats_table, :success_count, success_count)
    :ets.update_counter(stats_table, :error_count, error_count)
  end

  defp validate_sha256!(geolite_sha256_path, geolite_zip_path) do
    sha256_content = File.read!(geolite_sha256_path)
    [sha256, _] = String.split(sha256_content)

    zip_sha256 =
      Base.encode16(:crypto.hash(:sha256, File.read!(geolite_zip_path)), case: :lower)

    if sha256 != zip_sha256 do
      raise "sha256 mismatch"
    end

    sha256
  end

  defp download_url do
    Application.get_env(:geo_ip_server, GeoIpServer.Geolite2City)[:download_url] <>
      Application.get_env(:geo_ip_server, GeoIpServer.Geolite2City)[:license_key]
  end

  defp download_url_sha256 do
    Application.get_env(:geo_ip_server, GeoIpServer.Geolite2City)[:download_url_sha256] <>
      Application.get_env(:geo_ip_server, GeoIpServer.Geolite2City)[:license_key]
  end

  defp unzip_file_list(folder_prefix) do
    @unzip_file_list
    |> Enum.map(fn file_name -> String.to_charlist(Path.join([folder_prefix, file_name])) end)
  end

  defp log_invalid_changeset(changeset, csv) do
    changes =
      GeoIpServer.Utils.struct_from_map(
        changeset.changes,
        to: file_name_to_struct(csv)
      )

    errors =
      Enum.map_join(
        changeset.errors,
        ", ",
        fn {key, value} -> "#{key} #{elem(value, 0)}" end
      )

    Logger.info("failed row validations, changes: [#{changes}], errors: [#{errors}]")
  end

  defp convert_row_to_changeset(row, now, csv) when csv == @locations,
    do: Location.convert_row_to_changeset(row, now)

  defp convert_row_to_changeset(row, now, csv) when csv == @blocks_ipv4,
    do: BlockIpv4.convert_row_to_changeset(row, now)

  defp convert_row_to_changeset(row, now, csv) when csv == @blocks_ipv6,
    do: BlockIpv6.convert_row_to_changeset(row, now)

  defp insert_to_db(changesets, csv) when csv == @locations,
    do:
      Repo.insert_all({"geolite2_city_locations", Location}, changesets,
        on_conflict: :replace_all,
        conflict_target: [:geoname_id]
      )

  defp insert_to_db(changesets, csv) when csv == @blocks_ipv4,
    do:
      Repo.insert_all({"geolite2_city_blocks_ipv4", BlockIpv4}, changesets,
        on_conflict: :replace_all,
        conflict_target: [:network]
      )

  defp insert_to_db(changesets, csv) when csv == @blocks_ipv6,
    do:
      Repo.insert_all({"geolite2_city_blocks_ipv6", BlockIpv6}, changesets,
        on_conflict: :replace_all,
        conflict_target: [:network]
      )

  defp get_locations_for_ip(ip_address, type: type) do
    case parse_ip_address(ip_address, type: type) do
      {:ok, _} ->
        {_, val} =
          Cache.fetch(ip_address, fn ipadr -> run_locations_query(ipadr, type: type) end)

        {:ok, val}

      {:error, :einval} ->
        {:error, :invalid_ip}
    end
  end

  defp run_locations_query(ip_address, type: type) do
    query =
      Repo.query("""
      SELECT l.*
      FROM geolite2_city_blocks_#{table_suffix(type)} AS r
      JOIN geolite2_city_locations AS l
      ON l.geoname_id = r.geoname_id
      WHERE r.network >>= '#{ip_address}'
      """)

    ret =
      case query do
        {:ok, res} ->
          map_from_sql_query_result(res)

        {:error, msg} ->
          Logger.error("SQL query failed: #{msg}")
          []
      end

    {:commit, ret}
  end

  defp get_block_ip(cidr, type: type) do
    with {:ok, _} <- EctoNetwork.CIDR.cast(cidr),
         {:ok, res} <-
           Repo.query(
             "SELECT r.* " <>
               "FROM geolite2_city_blocks_#{table_suffix(type)} AS r " <>
               "WHERE r.network >>= '#{cidr}'" <>
               "LIMIT 1"
           ) do
      case struct_from_sql_query_result(res, to: get_module(type)) do
        [] -> {:error, :not_found}
        rec -> {:ok, hd(rec)}
      end
    else
      :error -> {:error, :invalid_ip}
      {:error, err} -> {:error, "SQL query failed: #{err}"}
    end
  end

  defp parse_ip_address(addr, type: type) when type == :ip4 do
    :inet.parse_ipv4strict_address(to_charlist(addr))
  end

  defp parse_ip_address(addr, type: type) when type == :ip6,
    do: :inet.parse_ipv6strict_address(to_charlist(addr))

  defp file_name_to_struct(csv) when csv == @locations, do: %Location{}
  defp file_name_to_struct(csv) when csv == @blocks_ipv4, do: %BlockIpv4{}
  defp file_name_to_struct(csv) when csv == @blocks_ipv6, do: %BlockIpv6{}

  defp table_suffix(type) when type == :ip4, do: "ipv4"
  defp table_suffix(type) when type == :ip6, do: "ipv6"

  defp get_module(type) when type == :ip4, do: BlockIpv4
  defp get_module(type) when type == :ip6, do: BlockIpv6
end
