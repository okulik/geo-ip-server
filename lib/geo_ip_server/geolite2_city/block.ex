defmodule GeoIpServer.Geolite2City.Block do
  @moduledoc """
  Fields and changeset logic shared by the `BlockIpv4` and `BlockIpv6` schemas.
  """

  import Ecto.Changeset

  require Logger

  @fields [
    geoname_id: :integer,
    registered_country_geoname_id: :integer,
    represented_country_geoname_id: :integer,
    is_anonymous_proxy: :boolean,
    is_satellite_provider: :boolean,
    postal_code: :string,
    latitude: :float,
    longitude: :float,
    accuracy_radius: :integer,
    is_anycast: :boolean
  ]

  # Columns in the order they appear in the GeoLite2 blocks CSV files.
  @columns [:network | Keyword.keys(@fields)]
  @column_count length(@columns)

  @doc """
  Returns the non-key fields of a block schema with their types.
  """
  def fields, do: @fields

  @doc """
  Builds a changeset for a `BlockIpv4` or `BlockIpv6` struct.
  """
  def changeset(block, attrs) do
    block
    |> cast(attrs, @columns ++ [:inserted_at, :updated_at])
    |> validate_required([:network, :inserted_at, :updated_at])
    |> validate_length(:postal_code, max: 255)
    |> validate_number(:latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> validate_number(:accuracy_radius, greater_than_or_equal_to: 0)
  end

  @doc """
  Converts a row from a GeoLite2 blocks CSV file to a changeset for the given block struct.
  """
  def convert_row_to_changeset(block, row, now) when length(row) == @column_count do
    attrs =
      @columns
      |> Enum.zip(row)
      |> Map.new()
      |> Map.merge(%{inserted_at: now, updated_at: now})

    changeset(block, attrs)
  end

  def convert_row_to_changeset(block, row, _now) do
    Logger.info("invalid row format: #{inspect(row)}")

    block
    |> changeset(%{})
    |> add_error(:msg, "invalid row format")
  end
end
