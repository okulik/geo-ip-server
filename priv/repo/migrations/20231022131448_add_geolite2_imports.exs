defmodule GeoIpServer.Repo.Migrations.AddGeolite2Imports do
  use Ecto.Migration

  def change do
    create table(:geolite2_imports) do
      add(:import_file, :string, null: false)
      add(:timestamp, :string, null: false)
      add(:import_sha256, :string, null: false)
      add(:success_count, :int, default: 0)
      add(:error_count, :int, default: 0)
      add(:last_error, :string)
      add(:running_time, :int, default: 0)
      add(:created_at, :utc_datetime, null: false)
    end

    create index(:geolite2_imports, [:created_at])
  end
end
