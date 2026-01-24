#!/bin/bash
set -e

# Skrypt tworzacy dodatkowa baze i uzytkownika dla n8n
# Uruchamiany automatycznie przez PostgreSQL przy pierwszym starcie

if [ -n "${POSTGRES_N8N_USER:-}" ] && [ -n "${POSTGRES_N8N_PASSWORD:-}" ] && [ -n "${POSTGRES_N8N_DB:-}" ]; then
    echo "Creating database and user for n8n..."

    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
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
