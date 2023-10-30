defmodule GeoIpServer.Geolite2City.Location do
  use Ecto.Schema

  import Ecto.Changeset

  require Logger

  @moduledoc """
  Contains the schema for the locations table.
  """

  @primary_key {:geoname_id, :integer, []}
  schema "geolite2_city_locations" do
    field(:locale_code, :string)
    field(:continent_code, :string)
    field(:continent_name, :string)
    field(:country_iso_code, :string)
    field(:country_name, :string)
    field(:subdivision_1_iso_code, :string)
    field(:subdivision_1_name, :string)
    field(:subdivision_2_iso_code, :string)
    field(:subdivision_2_name, :string)
    field(:city_name, :string)
    field(:metro_code, :integer)
    field(:time_zone, :string)
    field(:is_in_european_union, :boolean)
    timestamps(type: :utc_datetime)
  end

  @doc """
  Converts a row from the CSV file to a Location changeset.
  """
  def changeset(location, attrs) do
    location
    |> cast(attrs, [
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
      :is_in_european_union,
      :inserted_at,
      :updated_at
    ])
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
    |> validate_length(:continent_code, max: 255)
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
  def convert_row_to_changeset(row, now) do
    case row do
      [
        geoname_id,
        locale_code,
        continent_code,
        continent_name,
        country_iso_code,
        country_name,
        subdivision_1_iso_code,
        subdivision_1_name,
        subdivision_2_iso_code,
        subdivision_2_name,
        city_name,
        metro_code,
        time_zone,
        is_in_european_union
      ] ->
        changeset(%__MODULE__{}, %{
          geoname_id: geoname_id,
          locale_code: locale_code,
          continent_code: continent_code,
          continent_name: continent_name,
          country_iso_code: country_iso_code,
          country_name: country_name,
          subdivision_1_iso_code: subdivision_1_iso_code,
          subdivision_1_name: subdivision_1_name,
          subdivision_2_iso_code: subdivision_2_iso_code,
          subdivision_2_name: subdivision_2_name,
          city_name: city_name,
          metro_code: metro_code,
          time_zone: time_zone,
          is_in_european_union: is_in_european_union,
          inserted_at: now,
          updated_at: now
        })

      _ ->
        Logger.info("invalid row format: #{inspect(row)}")

        changeset(%__MODULE__{}, %{})
        |> Ecto.Changeset.add_error(:msg, "invalid row format")
    end
  end
end

defimpl String.Chars, for: GeoIpServer.Geolite2City.Location do
  import GeoIpServer.Utils, only: [val_for_log: 1]

  @doc """
  Converts a Location struct to a string.
  """
  def to_string(%GeoIpServer.Geolite2City.Location{} = location) do
    [
      "geoname_id: #{val_for_log(location.geoname_id)}",
      "locale_code: #{val_for_log(location.locale_code)}",
      "continent_code: #{val_for_log(location.continent_code)}",
      "continent_name: #{val_for_log(location.continent_name)}",
      "country_iso_code: #{val_for_log(location.country_iso_code)}",
      "country_name: #{val_for_log(location.country_name)}",
      "subdivision_1_iso_code: #{val_for_log(location.subdivision_1_iso_code)}",
      "subdivision_1_name: #{val_for_log(location.subdivision_1_name)}",
      "subdivision_2_iso_code: #{val_for_log(location.subdivision_2_iso_code)}",
      "subdivision_2_name: #{val_for_log(location.subdivision_2_name)}",
      "city_name: #{val_for_log(location.city_name)}",
      "metro_code: #{val_for_log(location.metro_code)}",
      "time_zone: #{val_for_log(location.time_zone)}",
      "is_in_european_union: #{val_for_log(location.is_in_european_union)}",
      "inserted_at: #{val_for_log(location.inserted_at)}",
      "updated_at: #{val_for_log(location.updated_at)}"
    ]
    |> Enum.join(", ")
  end
end
