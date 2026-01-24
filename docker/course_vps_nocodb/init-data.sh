#!/bin/bash
set -e

# =============================================================================
# PostgreSQL Init Script
# =============================================================================
# Skrypt tworzacy baze danych i uzytkownika dla NocoDB
# Uruchamiany automatycznie przez PostgreSQL przy pierwszym starcie
# =============================================================================

echo "=== PostgreSQL Init Script ==="

# -----------------------------------------------------------------------------
# Tworzenie bazy i uzytkownika dla NocoDB
# -----------------------------------------------------------------------------
if [ -n "${POSTGRES_NOCODB_USER:-}" ] && [ -n "${POSTGRES_NOCODB_PASSWORD:-}" ] && [ -n "${POSTGRES_NOCODB_DB:-}" ]; then
    echo "Creating database and user for NocoDB..."

    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        -- Utworz baze danych dla NocoDB
        CREATE DATABASE ${POSTGRES_NOCODB_DB};

        -- Utworz uzytkownika NocoDB
        CREATE USER ${POSTGRES_NOCODB_USER} WITH PASSWORD '${POSTGRES_NOCODB_PASSWORD}';

        -- Nadaj uprawnienia do bazy NocoDB
        GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_NOCODB_DB} TO ${POSTGRES_NOCODB_USER};
EOSQL

    # Nadaj uprawnienia do schema public w bazie NocoDB
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_NOCODB_DB" <<-EOSQL
        GRANT CREATE ON SCHEMA public TO ${POSTGRES_NOCODB_USER};
        GRANT ALL ON SCHEMA public TO ${POSTGRES_NOCODB_USER};
EOSQL

    echo "Database ${POSTGRES_NOCODB_DB} and user ${POSTGRES_NOCODB_USER} created successfully!"
else
    echo "ERROR: NocoDB database variables not set!"
    exit 1
fi

echo "=== PostgreSQL Init Complete ==="
