#!/bin/bash
# =============================================================================
# INIT SCRIPT - WERSJA LOKALNA
# =============================================================================
# Ten skrypt automatycznie:
# - Sprawdza wymagania systemowe
# - Przygotowuje plik .env
# - Opcjonalnie generuje silne hasla
# - Uruchamia setup.sh
#
# Dla srodowiska lokalnego (nauka, development) - nie wymaga domen ani SSL
# =============================================================================

set -e

# Kolory dla komunikatow
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}=========================================="
echo "  INIT - Konfiguracja lokalnego stacka"
echo -e "==========================================${NC}"
echo ""

# =============================================================================
# 1. SPRAWDZENIE WYMAGAN SYSTEMOWYCH
# =============================================================================
echo -e "${CYAN}[1/4] Sprawdzanie wymagan systemowych...${NC}"

MISSING_DEPS=()

if ! command -v docker &> /dev/null; then
    MISSING_DEPS+=("docker")
fi

if ! docker compose version &> /dev/null; then
    MISSING_DEPS+=("docker-compose")
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo -e "${RED}BLAD: Brakujace zaleznosci:${NC}"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo "Zainstaluj brakujace pakiety i uruchom skrypt ponownie."
    echo "Na macOS: brew install docker"
    echo "Na Ubuntu/Debian: sudo apt install docker.io docker-compose-plugin"
    exit 1
fi

echo -e "${GREEN}[OK]${NC} Wszystkie wymagania spelnione"

# =============================================================================
# 2. PRZYGOTOWANIE PLIKU .env
# =============================================================================
echo ""
echo -e "${CYAN}[2/4] Przygotowanie pliku .env...${NC}"

if [ -f .env ]; then
    echo -e "${YELLOW}Plik .env juz istnieje.${NC}"
    read -p "Czy chcesz go nadpisac? [t/N]: " OVERWRITE
    OVERWRITE=${OVERWRITE:-N}
    if [[ "$OVERWRITE" =~ ^[Tt]$ ]]; then
        cp .env.example .env
        echo -e "${GREEN}[OK]${NC} Plik .env nadpisany"
    else
        echo "Pomijam kopiowanie - uzywam istniejacego pliku .env"
    fi
else
    cp .env.example .env
    echo -e "${GREEN}[OK]${NC} Plik .env utworzony z domyslnymi wartosciami"
fi

# =============================================================================
# 3. OPCJONALNE GENEROWANIE SILNYCH HASEL
# =============================================================================
echo ""
echo -e "${CYAN}[3/4] Konfiguracja hasel...${NC}"
echo ""
echo "Domyslne hasla sa wystarczajace do nauki na lokalnej maszynie."
echo "Mozesz jednak wygenerowac silne hasla jesli wolisz."
echo ""
read -p "Czy chcesz wygenerowac silne hasla? [t/N]: " GENERATE_PASSWORDS
GENERATE_PASSWORDS=${GENERATE_PASSWORDS:-N}

if [[ "$GENERATE_PASSWORDS" =~ ^[Tt]$ ]]; then
    # Sprawdz czy openssl jest dostepne
    if ! command -v openssl &> /dev/null; then
        echo -e "${RED}BLAD: openssl nie jest zainstalowane.${NC}"
        echo "Zainstaluj openssl lub uzyj domyslnych hasel."
        echo "Na macOS: brew install openssl"
        echo "Na Ubuntu/Debian: sudo apt install openssl"
        exit 1
    fi

    echo ""
    echo "Generowanie silnych hasel..."

    REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
    POSTGRES_NOCODB_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
    POSTGRES_N8N_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
    N8N_ENCRYPTION_KEY=$(openssl rand -base64 32 | tr -d '\n')
    NC_JWT_SECRET=$(openssl rand -hex 32 | tr -d '\n')
    MINIO_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
    QDRANT_API_KEY=$(openssl rand -base64 32 | tr -d '\n')

    # Funkcja do bezpiecznej podmiany (escape specjalnych znakow)
    safe_replace() {
        local search="$1"
        local replace="$2"
        local file="$3"
        # Escape znakow specjalnych w replace (szczegolnie / i &)
        replace=$(printf '%s\n' "$replace" | sed 's/[&/\]/\\&/g')
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|${search}|${replace}|g" "$file"
        else
            sed -i "s|${search}|${replace}|g" "$file"
        fi
    }

    # Podmiana wartosci w .env
    safe_replace "REDIS_PASSWORD=local_redis_password" "REDIS_PASSWORD=${REDIS_PASSWORD}" .env
    safe_replace "POSTGRES_PASSWORD=local_postgres_admin_password" "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" .env
    safe_replace "POSTGRES_NOCODB_PASSWORD=local_nocodb_password" "POSTGRES_NOCODB_PASSWORD=${POSTGRES_NOCODB_PASSWORD}" .env
    safe_replace "POSTGRES_N8N_PASSWORD=local_n8n_password" "POSTGRES_N8N_PASSWORD=${POSTGRES_N8N_PASSWORD}" .env
    safe_replace "N8N_ENCRYPTION_KEY=local_encryption_key_32_characters" "N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}" .env
    safe_replace "NC_JWT_SECRET=local-jwt-secret-change-in-production" "NC_JWT_SECRET=${NC_JWT_SECRET}" .env
    safe_replace "MINIO_ROOT_PASSWORD=local_minio_password" "MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}" .env
    safe_replace "QDRANT_API_KEY=local_qdrant_api_key" "QDRANT_API_KEY=${QDRANT_API_KEY}" .env

    echo -e "${GREEN}[OK]${NC} Silne hasla wygenerowane i zapisane"
    echo ""
    echo -e "${YELLOW}Wygenerowane hasla:${NC}"
    echo "  REDIS_PASSWORD:          ${REDIS_PASSWORD}"
    echo "  POSTGRES_PASSWORD:       ${POSTGRES_PASSWORD}"
    echo "  POSTGRES_NOCODB_PASSWORD: ${POSTGRES_NOCODB_PASSWORD}"
    echo "  POSTGRES_N8N_PASSWORD:   ${POSTGRES_N8N_PASSWORD}"
    echo "  N8N_ENCRYPTION_KEY:      ${N8N_ENCRYPTION_KEY}"
    echo "  NC_JWT_SECRET:           ${NC_JWT_SECRET}"
    echo "  MINIO_ROOT_PASSWORD:     ${MINIO_ROOT_PASSWORD}"
    echo "  QDRANT_API_KEY:          ${QDRANT_API_KEY}"
    echo ""
    echo -e "${YELLOW}UWAGA: Zapisz te hasla w bezpiecznym miejscu!${NC}"
else
    echo -e "${GREEN}[OK]${NC} Uzywam domyslnych hasel (OK dla lokalnego srodowiska)"
fi

# =============================================================================
# 4. URUCHOMIENIE SETUP.SH
# =============================================================================
echo ""
echo -e "${CYAN}[4/4] Uruchamianie setup.sh...${NC}"
echo ""

./setup.sh

echo ""
echo -e "${GREEN}=========================================="
echo "  INICJALIZACJA ZAKONCZONA POMYSLNIE!"
echo -e "==========================================${NC}"
echo ""
echo "Nastepne kroki:"
echo "  1. Uruchom stack:    docker compose up -d"
echo "  2. Poczekaj ~30-60 sekund na uruchomienie uslug"
echo "  3. Sprawdz status:   docker compose ps"
echo ""
echo "Adresy aplikacji (po uruchomieniu):"
echo -e "  - n8n:              ${GREEN}http://localhost:5678${NC}"
echo -e "  - NocoDB:           ${GREEN}http://localhost:8080${NC}"
echo -e "  - MinIO Console:    ${GREEN}http://localhost:9001${NC}"
echo -e "  - Qdrant Dashboard: ${GREEN}http://localhost:6333/dashboard${NC}"
echo ""
