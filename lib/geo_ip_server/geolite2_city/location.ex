defmodule GeoIpServer.Geolite2City.Location do
  @moduledoc """
  Contains the schema for the geolite2_city_locations table.
  """

  use Ecto.Schema

  import Ecto.Changeset

  require Logger

  # Columns in the order they appear in the GeoLite2 locations CSV file.
  @columns [
    :geoname_id,
    :locale_code,
    :continent_code,
    :continent_name,
    :country_iso_code,
    :country_name,
    :subdivision_1_iso_code,
    :subdivision_1_name,
    :subdivision_2_iso_code,
    :subdivision_2_name,
    :city_name,
    :metro_code,
    :time_zone,
    :is_in_european_union
  ]
  @column_count length(@columns)

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:geoname_id, :integer, []}
  schema "geolite2_city_locations" do
    field :locale_code, :string
    field :continent_code, :string
    field :continent_name, :string
    field :country_iso_code, :string
    field :country_name, :string
    field :subdivision_1_iso_code, :string
    field :subdivision_1_name, :string
    field :subdivision_2_iso_code, :string
    field :subdivision_2_name, :string
    field :city_name, :string
    field :metro_code, :integer
    field :time_zone, :string
    field :is_in_european_union, :boolean
    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a Location changeset.
  """
  def changeset(location, attrs) do
    location
    |> cast(attrs, @columns ++ [:inserted_at, :updated_at])
    |> validate_required([
      :geoname_id,
      :locale_code,
      :continent_code,
      :continent_name,
      :time_zone,
      :is_in_european_union,
      :inserted_at,
      :updated_at
    ])
    |> validate_length(:locale_code, is: 2)
    |> validate_length(:continent_code, is: 2)
    |> validate_length(:continent_name, max: 255)
    |> validate_length(:country_iso_code, is: 2)
    |> validate_length(:subdivision_1_iso_code, max: 3)
    |> validate_length(:subdivision_1_name, max: 255)
    |> validate_length(:subdivision_2_iso_code, max: 3)
    |> validate_length(:subdivision_2_name, max: 255)
    |> validate_length(:time_zone, max: 255)
  end

  @doc """
  Converts a row from the CSV file to a Location changeset.
  """
  def convert_row_to_changeset(row, now) when length(row) == @column_count do
    attrs =
      @columns
      |> Enum.zip(row)
      |> Map.new()
      |> Map.merge(%{inserted_at: now, updated_at: now})

    changeset(%__MODULE__{}, attrs)
  end

  def convert_row_to_changeset(row, _now) do
    Logger.info("invalid row format: #{inspect(row)}")

    %__MODULE__{}
    |> changeset(%{})
    |> add_error(:msg, "invalid row format")
  end
end
