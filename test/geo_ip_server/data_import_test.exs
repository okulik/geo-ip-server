defmodule GeoIpServer.GeoDataTest do
  use GeoIpServer.DataCase

  import GeoIpServer.DataImportFixtures

  alias GeoIpServer.DataImport
  alias GeoIpServer.DataImport.Geolite2Import

  describe "data import tests" do
    test "get_geolite2_import/1 returns the existing import record" do
      imp = geolite2_import_fixture()

      geo2import = DataImport.get_geolite2_import(imp.id)

      assert geo2import.import_file == imp.import_file
      assert geo2import.timestamp == imp.timestamp
      assert geo2import.import_sha256 == imp.import_sha256
      assert geo2import.success_count == imp.success_count
      assert geo2import.error_count == imp.error_count
      assert geo2import.running_time == imp.running_time
      assert geo2import.created_at == imp.created_at
    end

    test "get_geolite2_import/1 returns all existing import records" do
      imp = geolite2_import_fixture()

      geo2imports = DataImport.get_all_geolite2_imports()

      assert length(geo2imports) == 1
      geo2import = hd(geo2imports)
      assert geo2import.import_file == imp.import_file
      assert geo2import.timestamp == imp.timestamp
      assert geo2import.import_sha256 == imp.import_sha256
      assert geo2import.success_count == imp.success_count
      assert geo2import.error_count == imp.error_count
      assert geo2import.running_time == imp.running_time
      assert geo2import.created_at == imp.created_at
    end

    test "create_geolite2_import!/1 with valid attributes creates Geolite2Import" do
      attrs = %{
        import_file: "foo.csv",
        timestamp: "20231024",
        import_sha256: "123",
        success_count: 100,
        error_count: 0,
        running_time: 1000,
        created_at: ~U[2023-10-08 02:00:00Z]
      }

      geo2import = DataImport.create_geolite2_import!(attrs)
      assert %Geolite2Import{} = geo2import
      assert geo2import.import_file == "foo.csv"
      assert geo2import.timestamp == "20231024"
      assert geo2import.import_sha256 == "123"
      assert geo2import.success_count == 100
      assert geo2import.error_count == 0
      assert geo2import.running_time == 1000
      assert geo2import.created_at == ~U[2023-10-08 02:00:00Z]
    end

    test "create_block_ipv4!/1 with invalid data returns error" do
      assert_raise(Ecto.InvalidChangesetError, fn ->
        DataImport.create_geolite2_import!(%{})
      end)
    end
  end
end
