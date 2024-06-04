defmodule GeoIpServer.Geolite2City.BlockIpv6 do
  use Ecto.Schema

  import Ecto.Changeset

  require Logger

  @moduledoc """
  Contains the schema for the locations table.
  """

  @primary_key {:network, EctoNetwork.CIDR, []}
  schema "geolite2_city_blocks_ipv6" do
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
  Converts a row from the CSV file to a BlockIpv6 changeset.
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
  Converts a row from the CSV file to a BlockIpv6 changeset.
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

defimpl String.Chars, for: GeoIpServer.Geolite2City.BlockIpv6 do
  import GeoIpServer.Utils, only: [val_for_log: 1]

  @doc """
  Converts a BlockIpv6 struct to a string.
  """
  def to_string(%GeoIpServer.Geolite2City.BlockIpv6{} = block_ipv6) do
    [
      "network: #{val_for_log(block_ipv6.network)}",
      "geoname_id: #{val_for_log(block_ipv6.geoname_id)}",
      "registered_country_geoname_id: #{val_for_log(block_ipv6.registered_country_geoname_id)}",
      "represented_country_geoname_id: #{val_for_log(block_ipv6.represented_country_geoname_id)}",
      "is_anonymous_proxy: #{val_for_log(block_ipv6.is_anonymous_proxy)}",
      "is_satellite_provider: #{val_for_log(block_ipv6.is_satellite_provider)}",
      "postal_code: #{val_for_log(block_ipv6.postal_code)}",
      "latitude: #{val_for_log(block_ipv6.latitude)}",
      "longitude: #{val_for_log(block_ipv6.longitude)}",
      "accuracy_radius: #{val_for_log(block_ipv6.accuracy_radius)}",
      "is_anycast: #{val_for_log(block_ipv6.is_anycast)}",
      "inserted_at: #{val_for_log(block_ipv6.inserted_at)}",
      "updated_at: #{val_for_log(block_ipv6.updated_at)}"
    ]
    |> Enum.join(", ")
  end
end
