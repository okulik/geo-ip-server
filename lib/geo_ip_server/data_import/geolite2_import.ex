defmodule GeoIpServer.DataImport.Geolite2Import do
  use Ecto.Schema

  import Ecto.Changeset

  @moduledoc """
  Contains the schema for the geolite2_imports table.
  """

  schema "geolite2_imports" do
    field(:import_file, :string)
    field(:timestamp, :string)
    field(:import_sha256, :string)
    field(:success_count, :integer)
    field(:error_count, :integer)
    field(:last_error, :string)
    field(:running_time, :integer)
    field(:created_at, :utc_datetime)
  end

  @doc """
  A geolite2_import changeset for writing CSV import stats.
  """
  def changeset(geolite2_import, attrs) do
    geolite2_import
    |> cast(attrs, [
      :import_file,
      :timestamp,
      :import_sha256,
      :success_count,
      :error_count,
      :last_error,
      :running_time,
      :created_at
    ])
    |> validate_required([
      :import_file,
      :timestamp,
      :import_sha256,
      :success_count,
      :error_count,
      :running_time,
      :created_at
    ])
    |> validate_number(:success_count, greater_than_or_equal_to: 0)
    |> validate_number(:error_count, greater_than_or_equal_to: 0)
    |> validate_number(:running_time, greater_than_or_equal_to: 0)
  end
end
