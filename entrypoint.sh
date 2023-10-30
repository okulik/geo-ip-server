#!/bin/bash

# Wait until Postgres is ready.
while ! pg_isready -q -h $PGHOST -p $PGPORT -U $PGUSER
do
  echo "$(date) - waiting for database to start"
  sleep 2
done

# Create, migrate, and seed database if it doesn't exist.
if [[ -z `psql -Atqc "\\list $PGDATABASE"` ]]; then
  # ecto.setup is an alias for ["ecto.create", "ecto.migrate",
  #   "import_csv rel/overlays/seeds/cloud_data_dump.csv"]
  mix ecto.setup
else
  mix ecto.migrate
fi

exec mix phx.server
