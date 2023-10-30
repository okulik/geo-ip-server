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

defimpl String.Chars, for: GeoIpServer.DataImport.Geolite2Import do
  def to_string(%GeoIpServer.DataImport.Geolite2Import{} = geolite2_import) do
    [
      "import_file: #{geolite2_import.import_file}",
      "timestamp: #{geolite2_import.timestamp}",
      "import_sha256: #{geolite2_import.import_sha256}",
      "success_count: #{geolite2_import.success_count}",
      "error_count: #{geolite2_import.error_count}",
      "last_error: #{geolite2_import.last_error}",
      "running_time: #{geolite2_import.running_time}",
      "created_at: #{geolite2_import.created_at}"
    ]
    |> Enum.join(", ")
  end
end
