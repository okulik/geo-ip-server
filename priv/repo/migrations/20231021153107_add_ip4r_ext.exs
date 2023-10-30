defmodule GeoIpServer.Repo.Migrations.AddIp4rExt do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS ip4r"
  end
end
