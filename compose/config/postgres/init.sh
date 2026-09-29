#!/usr/bin/env bash
set -euo pipefail

: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"

create_database() {
  local database="$1"
  if ! psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --tuples-only --no-align \
    --command "SELECT 1 FROM pg_database WHERE datname = '$database'" | grep -qx 1; then
    createdb --username "$POSTGRES_USER" --owner "$POSTGRES_USER" "$database"
  fi
}

create_database nessie

for database in "$POSTGRES_DB" nessie; do
  psql --username "$POSTGRES_USER" --dbname "$database" --set=ON_ERROR_STOP=1 <<'SQL'
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
ALTER SCHEMA public OWNER TO CURRENT_USER;
SQL
done

psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --set=ON_ERROR_STOP=1 <<SQL
ALTER DATABASE "$POSTGRES_DB" SET idle_in_transaction_session_timeout = '5min';
ALTER DATABASE "$POSTGRES_DB" SET idle_session_timeout = '30min';
ALTER DATABASE nessie SET idle_in_transaction_session_timeout = '5min';
ALTER DATABASE nessie SET idle_session_timeout = '30min';
SQL
