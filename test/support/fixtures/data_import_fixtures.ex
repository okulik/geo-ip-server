defmodule GeoIpServer.DataImportFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GeoIpServer.Geolite2City` context.
  """

  alias GeoIpServer.DataImport

  @doc """
  Generate a BlockIpv4 entity.
  """
  def geolite2_import_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      import_file: "GeoLite2-City-Locations-en.csv",
      timestamp: "20231020",
      import_sha256: "16c292952e41bc6c80725328360b",
      success_count: 100,
      error_count: 0,
      last_error: nil,
      running_time: 3587,
      created_at: ~U[2023-10-27 10:34:00Z]
    })
    |> DataImport.create_geolite2_import!()
  end
end
