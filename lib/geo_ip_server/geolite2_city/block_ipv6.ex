defmodule GeoIpServer.Geolite2City.BlockIpv6 do
  @moduledoc """
  Contains the schema for the geolite2_city_blocks_ipv6 table.
  """

  use Ecto.Schema

  alias GeoIpServer.Geolite2City.Block

  @primary_key {:network, EctoNetwork.CIDR, []}
  schema "geolite2_city_blocks_ipv6" do
    for {name, type} <- Block.fields(), do: field(name, type)
    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a BlockIpv6 changeset.
  """
  defdelegate changeset(block_ipv6, attrs), to: Block

  @doc """
  Converts a row from the CSV file to a BlockIpv6 changeset.
  """
  def convert_row_to_changeset(row, now),
    do: Block.convert_row_to_changeset(%__MODULE__{}, row, now)
end
