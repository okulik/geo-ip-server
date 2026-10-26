defmodule GeoIpServer.Geolite2City do
  @moduledoc """
  The Geolite2City context.
  """

  import Ecto.Query, only: [from: 2]

  alias GeoIpServer.Cache
  alias GeoIpServer.DataImport
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
  def get_block_ipv4(cidr), do: get_block(BlockIpv4, cidr)

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
  def get_block_ipv6(cidr), do: get_block(BlockIpv6, cidr)

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
    with {:ok, address} <- :inet.parse_strict_address(to_charlist(ip_address)),
         {:ok, [_ | _]} = ok <-
           Cache.fetch_or_store(ip_address, fn -> {:ok, locations_query(address)} end) do
      ok
    else
      {:ok, []} -> {:error, :not_found}
      {:error, :einval} -> {:error, :invalid_ip}
    end
  end

  @doc """
    Validates the sha256 of the downloaded zip file, extracts the required
    files from the zip file, and imports the extracted files into the database.
    This function is typically called from a CRON job, or from a mix task.
    Returns a list of Geolite2Import structs, one for each imported file.
    Locations are imported first, followed by BlockIpv4, and then BlockIpv6.
    Each file is saved to a separate table in the database.

    ## Examples

        iex> import_geolite_files!("/tmp/geolite2-2024-06-04-18-01-00")
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
  def import_geolite_files!(tmp_dir) do
    # Get the full paths to the downloaded files.
    [sha256_path] = Path.wildcard(Path.join(tmp_dir, "*.zip.sha256"))
    [zip_path] = Path.wildcard(Path.join(tmp_dir, "*.zip"))

    # Validate the sha256 of the downloaded geoip zip file.
    import_sha256 = validate_sha256!(sha256_path, zip_path)

    # Basename of the zip file without the extension (e.g. GeoLite2-City-CSV_20232310).
    zip_folder = Path.basename(zip_path, ".zip")

    # Extract the timestamp from the zip folder name (e.g. 20232310).
    @zip_folder_prefix <> ts = zip_folder

    # Extract only required files from the zip file.
    file_list =
      case :zip.unzip(to_charlist(zip_path),
             file_list: unzip_file_list(zip_folder),
             cwd: to_charlist(tmp_dir)
           ) do
        {:ok, file_list} -> file_list
        {:error, reason} -> raise "failed to unzip #{zip_path}: #{inspect(reason)}"
      end

    Enum.map(file_list, fn file ->
      import_csv_file!(tmp_dir, zip_folder, Path.basename(file), sha: import_sha256, ts: ts)
    end)
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
  def import_csv_file!(temp_dir, zip_folder, csv, opts) do
    Path.join([temp_dir, zip_folder, csv])
    |> File.stream!()
    |> import_from_stream(csv, opts)
  end

  def import_from_stream(file_stream, csv, opts) do
    import_sha256 = Keyword.fetch!(opts, :sha)
    ts = Keyword.fetch!(opts, :ts)
    schema = schema_for(csv)
    t0 = System.monotonic_time(:millisecond)

    {:ok, geolite2_import} =
      Repo.transaction(
        fn ->
          now = DateTime.utc_now()

          {success_count, error_count} =
            file_stream
            |> CSV.parse_stream(skip_headers: true)
            |> Stream.chunk_every(@csv_batch_size)
            |> Enum.reduce({0, 0}, fn rows, {success_count, error_count} ->
              {valid, invalid} =
                rows
                |> Enum.map(&schema.convert_row_to_changeset(&1, now))
                |> Enum.split_with(& &1.valid?)

              Enum.each(invalid, &log_invalid_changeset/1)
              insert_all(schema, Enum.map(valid, & &1.changes))

              {success_count + length(valid), error_count + length(invalid)}
            end)

          running_time = System.monotonic_time(:millisecond) - t0

          :telemetry.execute(
            [:geo_ip_server, :csv_import, :duration],
            %{took: running_time},
            %{csv: csv}
          )

          DataImport.create_geolite2_import!(%{
            import_file: csv,
            import_sha256: import_sha256,
            success_count: success_count,
            error_count: error_count,
            running_time: running_time,
            created_at: now,
            timestamp: ts
          })
        end,
        timeout: :infinity
      )

    geolite2_import
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

  defp unzip_file_list(folder_prefix) do
    Enum.map(@unzip_file_list, &to_charlist(Path.join(folder_prefix, &1)))
  end

  defp log_invalid_changeset(changeset) do
    changes = GeoIpServer.Utils.struct_from_map(changeset.changes, to: changeset.data)

    errors =
      Enum.map_join(changeset.errors, ", ", fn {key, {message, _opts}} -> "#{key} #{message}" end)

    Logger.info("failed row validations, changes: [#{changes}], errors: [#{errors}]")
  end

  defp schema_for(@locations), do: Location
  defp schema_for(@blocks_ipv4), do: BlockIpv4
  defp schema_for(@blocks_ipv6), do: BlockIpv6

  defp insert_all(schema, entries) do
    Repo.insert_all(schema, entries,
      on_conflict: :replace_all,
      conflict_target: schema.__schema__(:primary_key)
    )
  end

  defp locations_query(address) do
    block_schema = if tuple_size(address) == 4, do: BlockIpv4, else: BlockIpv6

    Repo.all(
      from(l in Location,
        join: b in ^block_schema,
        on: b.geoname_id == l.geoname_id,
        where: fragment("? >>= ?", b.network, ^%Postgrex.INET{address: address})
      )
    )
  end

  defp get_block(schema, cidr) do
    with {:ok, network} <- EctoNetwork.CIDR.cast(cidr),
         %{} = block <-
           Repo.one(
             from(b in schema,
               where: fragment("? >>= ?", b.network, ^network),
               limit: 1
             )
           ) do
      {:ok, block}
    else
      :error -> {:error, :invalid_ip}
      nil -> {:error, :not_found}
    end
  end
end
