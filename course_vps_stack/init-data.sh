#!/bin/bash
set -e

# =============================================================================
# PostgreSQL Init Script
# =============================================================================
# Skrypt tworzacy bazy danych i uzytkownikow dla aplikacji
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
    echo "SETUP INFO: NocoDB database variables not set, skipping NocoDB database creation."
fi

# -----------------------------------------------------------------------------
# Tworzenie bazy i uzytkownika dla n8n
# -----------------------------------------------------------------------------
if [ -n "${POSTGRES_N8N_USER:-}" ] && [ -n "${POSTGRES_N8N_PASSWORD:-}" ] && [ -n "${POSTGRES_N8N_DB:-}" ]; then
    echo "Creating database and user for n8n..."

    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        -- Utworz baze danych dla n8n
        CREATE DATABASE ${POSTGRES_N8N_DB};

        -- Utworz uzytkownika n8n
        CREATE USER ${POSTGRES_N8N_USER} WITH PASSWORD '${POSTGRES_N8N_PASSWORD}';

        -- Nadaj uprawnienia do bazy n8n
        GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_N8N_DB} TO ${POSTGRES_N8N_USER};
EOSQL

    # Nadaj uprawnienia do schema public w bazie n8n
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_N8N_DB" <<-EOSQL
        GRANT CREATE ON SCHEMA public TO ${POSTGRES_N8N_USER};
        GRANT ALL ON SCHEMA public TO ${POSTGRES_N8N_USER};
EOSQL

    echo "Database ${POSTGRES_N8N_DB} and user ${POSTGRES_N8N_USER} created successfully!"
else
    echo "SETUP INFO: n8n database variables not set, skipping n8n database creation."
fi

echo "=== PostgreSQL Init Complete ==="
