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

    # Sprawdz czy baza istnieje
    DB_EXISTS=$(psql -U "$POSTGRES_USER" -tAc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_NOCODB_DB}'" 2>/dev/null || echo "0")

    if [ "$DB_EXISTS" != "1" ]; then
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE ${POSTGRES_NOCODB_DB};"
        echo "Database ${POSTGRES_NOCODB_DB} created."
    else
        echo "Database ${POSTGRES_NOCODB_DB} already exists, skipping creation."
    fi

    # Sprawdz czy user istnieje
    USER_EXISTS=$(psql -U "$POSTGRES_USER" -tAc "SELECT 1 FROM pg_roles WHERE rolname='${POSTGRES_NOCODB_USER}'" 2>/dev/null || echo "0")

    if [ "$USER_EXISTS" != "1" ]; then
        # Utworz uzytkownika - uzywamy dollar-quoting dla bezpieczenstwa hasel
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE USER ${POSTGRES_NOCODB_USER} WITH PASSWORD \$\$${POSTGRES_NOCODB_PASSWORD}\$\$;"
        echo "User ${POSTGRES_NOCODB_USER} created."
    else
        # User istnieje - zaktualizuj haslo
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "ALTER USER ${POSTGRES_NOCODB_USER} WITH PASSWORD \$\$${POSTGRES_NOCODB_PASSWORD}\$\$;"
        echo "User ${POSTGRES_NOCODB_USER} already exists, password updated."
    fi

    # Nadaj uprawnienia
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_NOCODB_DB} TO ${POSTGRES_NOCODB_USER};"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_NOCODB_DB" -c "GRANT CREATE ON SCHEMA public TO ${POSTGRES_NOCODB_USER}; GRANT ALL ON SCHEMA public TO ${POSTGRES_NOCODB_USER};"

    echo "NocoDB database setup complete!"
else
    echo "SETUP INFO: NocoDB database variables not set, skipping NocoDB database creation."
fi

# -----------------------------------------------------------------------------
# Tworzenie bazy i uzytkownika dla n8n
# -----------------------------------------------------------------------------
if [ -n "${POSTGRES_N8N_USER:-}" ] && [ -n "${POSTGRES_N8N_PASSWORD:-}" ] && [ -n "${POSTGRES_N8N_DB:-}" ]; then
    echo "Creating database and user for n8n..."

    # Sprawdz czy baza istnieje
    DB_EXISTS=$(psql -U "$POSTGRES_USER" -tAc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_N8N_DB}'" 2>/dev/null || echo "0")

    if [ "$DB_EXISTS" != "1" ]; then
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE ${POSTGRES_N8N_DB};"
        echo "Database ${POSTGRES_N8N_DB} created."
    else
        echo "Database ${POSTGRES_N8N_DB} already exists, skipping creation."
    fi

    # Sprawdz czy user istnieje
    USER_EXISTS=$(psql -U "$POSTGRES_USER" -tAc "SELECT 1 FROM pg_roles WHERE rolname='${POSTGRES_N8N_USER}'" 2>/dev/null || echo "0")

    if [ "$USER_EXISTS" != "1" ]; then
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE USER ${POSTGRES_N8N_USER} WITH PASSWORD \$\$${POSTGRES_N8N_PASSWORD}\$\$;"
        echo "User ${POSTGRES_N8N_USER} created."
    else
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "ALTER USER ${POSTGRES_N8N_USER} WITH PASSWORD \$\$${POSTGRES_N8N_PASSWORD}\$\$;"
        echo "User ${POSTGRES_N8N_USER} already exists, password updated."
    fi

    # Nadaj uprawnienia
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_N8N_DB} TO ${POSTGRES_N8N_USER};"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_N8N_DB" -c "GRANT CREATE ON SCHEMA public TO ${POSTGRES_N8N_USER}; GRANT ALL ON SCHEMA public TO ${POSTGRES_N8N_USER};"

    echo "n8n database setup complete!"
else
    echo "SETUP INFO: n8n database variables not set, skipping n8n database creation."
fi

echo "=== PostgreSQL Init Complete ==="
