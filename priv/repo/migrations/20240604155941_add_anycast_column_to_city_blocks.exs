defmodule GeoIpServer.Repo.Migrations.AddAnycastColumnToCityBlocks do
  use Ecto.Migration

  def change do
    alter table(:geolite2_city_blocks_ipv4) do
      add(:is_anycast, :boolean, default: false)
    end

    alter table(:geolite2_city_blocks_ipv6) do
      add(:is_anycast, :boolean, default: false)
    end
  end
end
