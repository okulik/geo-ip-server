defmodule GeoIpServer.Geolite2City.BlockIpv4 do
  use Ecto.Schema

  import Ecto.Changeset

  require Logger

  @moduledoc """
  Contains the schema for the locations table.
  """

  @primary_key {:network, EctoNetwork.CIDR, []}
  schema "geolite2_city_blocks_ipv4" do
    field(:geoname_id, :integer)
    field(:registered_country_geoname_id, :integer)
    field(:represented_country_geoname_id, :integer)
    field(:is_anonymous_proxy, :boolean)
    field(:is_satellite_provider, :boolean)
    field(:postal_code, :string)
    field(:latitude, :float)
    field(:longitude, :float)
    field(:accuracy_radius, :integer)
    field(:is_anycast, :boolean)
    timestamps(type: :utc_datetime)
  end

  @doc """
  Converts a row from the CSV file to a BlockIpv4 changeset.
  """
  def changeset(location, attrs) do
    location
    |> cast(attrs, [
      :network,
      :geoname_id,
      :registered_country_geoname_id,
      :represented_country_geoname_id,
      :is_anonymous_proxy,
      :is_satellite_provider,
      :postal_code,
      :latitude,
      :longitude,
      :accuracy_radius,
      :is_anycast,
      :inserted_at,
      :updated_at
    ])
    |> validate_required([
      :network,
      :inserted_at,
      :updated_at
    ])
    |> validate_length(:postal_code, max: 255)
    |> validate_number(:latitude,
      greater_than_or_equal_to: -90,
      less_than_or_equal_to: 90
    )
    |> validate_number(:longitude,
      greater_than_or_equal_to: -180,
      less_than_or_equal_to: 180
    )
    |> validate_number(:accuracy_radius, greater_than_or_equal_to: 0)
  end

  @doc """
  Converts a row from the CSV file to a BlockIpv4 changeset.
  """
  def convert_row_to_changeset(row, now) do
    case row do
      [
        network,
        geoname_id,
        registered_country_geoname_id,
        represented_country_geoname_id,
        is_anonymous_proxy,
        is_satellite_provider,
        postal_code,
        latitude,
        longitude,
        accuracy_radius,
        is_anycast
      ] ->
        changeset(%__MODULE__{}, %{
          network: network,
          geoname_id: geoname_id,
          registered_country_geoname_id: registered_country_geoname_id,
          represented_country_geoname_id: represented_country_geoname_id,
          is_anonymous_proxy: is_anonymous_proxy,
          is_satellite_provider: is_satellite_provider,
          postal_code: postal_code,
          latitude: latitude,
          longitude: longitude,
          accuracy_radius: accuracy_radius,
          is_anycast: is_anycast,
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
