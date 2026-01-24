#!/bin/bash
# =============================================================================
# INIT SCRIPT - NOCODB WITH MINIO (VPS)
# =============================================================================
# Ten skrypt automatycznie:
# - Sprawdza wymagania systemowe
# - Konfiguruje domeny (interaktywnie)
# - Generuje wszystkie hasla i klucze
# - Przygotowuje srodowisko do uruchomienia
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
echo "  INIT - NocoDB with MinIO Stack"
echo -e "==========================================${NC}"
echo ""

# =============================================================================
# 1. SPRAWDZENIE WYMAGAN SYSTEMOWYCH
# =============================================================================
echo -e "${CYAN}[1/6] Sprawdzanie wymagan systemowych...${NC}"

MISSING_DEPS=()

if ! command -v docker &> /dev/null; then
    MISSING_DEPS+=("docker")
fi

if ! docker compose version &> /dev/null; then
    MISSING_DEPS+=("docker-compose")
fi

if ! command -v openssl &> /dev/null; then
    MISSING_DEPS+=("openssl")
fi

if ! command -v uuidgen &> /dev/null; then
    MISSING_DEPS+=("uuidgen (pakiet: uuid-runtime)")
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo -e "${RED}BLAD: Brakujace zaleznosci:${NC}"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo "Zainstaluj brakujace pakiety i uruchom skrypt ponownie."
    echo "Na Ubuntu/Debian: sudo apt install docker.io docker-compose-plugin uuid-runtime"
    exit 1
fi

echo -e "${GREEN}[OK]${NC} Wszystkie wymagania spelnione"

# =============================================================================
# 2. SPRAWDZENIE/KOPIOWANIE .env
# =============================================================================
echo ""
echo -e "${CYAN}[2/6] Przygotowanie pliku .env...${NC}"

if [ -f .env ]; then
    if grep -q "WPISZ_\|WYGENERUJ_\|twoja-domena.pl" .env; then
        echo -e "${YELLOW}Plik .env istnieje, ale nie jest skonfigurowany.${NC}"
        read -p "Czy nadpisac i skonfigurowac automatycznie? [T/n]: " OVERWRITE
        OVERWRITE=${OVERWRITE:-T}
        if [[ ! "$OVERWRITE" =~ ^[Tt]$ ]]; then
            echo "Przerwano. Skonfiguruj plik .env recznie."
            exit 0
        fi
        cp .env.example .env
    else
        echo -e "${YELLOW}Plik .env istnieje i jest juz skonfigurowany.${NC}"
        read -p "Czy chcesz go nadpisac? [t/N]: " OVERWRITE
        OVERWRITE=${OVERWRITE:-N}
        if [[ ! "$OVERWRITE" =~ ^[Tt]$ ]]; then
            echo "Pomijam konfiguracje .env - uzywam istniejacego pliku."
            echo "Uruchamiam setup.sh..."
            ./setup.sh
            exit 0
        fi
        cp .env.example .env
    fi
else
    cp .env.example .env
fi

echo -e "${GREEN}[OK]${NC} Plik .env przygotowany"

# =============================================================================
# 3. KONFIGURACJA DOMEN (INTERAKTYWNA)
# =============================================================================
echo ""
echo -e "${CYAN}[3/6] Konfiguracja domen...${NC}"
echo ""

# Pytanie o domene bazowa
while true; do
    read -p "Podaj domene bazowa (np. firma.pl): " BASE_DOMAIN
    if [ -z "$BASE_DOMAIN" ]; then
        echo -e "${RED}Domena nie moze byc pusta!${NC}"
    elif [[ "$BASE_DOMAIN" == *"twoja-domena"* ]]; then
        echo -e "${RED}Podaj swoja prawdziwa domene!${NC}"
    else
        break
    fi
done

# Domyslne subdomeny
DEFAULT_NOCODB="nocodb.${BASE_DOMAIN}"
DEFAULT_MINIO="minio.${BASE_DOMAIN}"

echo ""
echo "Domyslne subdomeny:"
echo -e "  - nocodb: ${GREEN}${DEFAULT_NOCODB}${NC}"
echo -e "  - minio:  ${GREEN}${DEFAULT_MINIO}${NC}"
echo ""

read -p "Uzyc domyslnych subdomen? [T/n]: " USE_DEFAULTS
USE_DEFAULTS=${USE_DEFAULTS:-T}

if [[ "$USE_DEFAULTS" =~ ^[Tt]$ ]]; then
    NOCODB_DOMAIN="$DEFAULT_NOCODB"
    MINIO_DOMAIN="$DEFAULT_MINIO"
else
    echo ""
    read -p "Podaj pelna domene dla nocodb [${DEFAULT_NOCODB}]: " NOCODB_DOMAIN
    NOCODB_DOMAIN=${NOCODB_DOMAIN:-$DEFAULT_NOCODB}

    read -p "Podaj pelna domene dla minio [${DEFAULT_MINIO}]: " MINIO_DOMAIN
    MINIO_DOMAIN=${MINIO_DOMAIN:-$DEFAULT_MINIO}
fi

echo ""
echo -e "${GREEN}[OK]${NC} Domeny skonfigurowane"

# =============================================================================
# 4. GENEROWANIE SEKRETOW
# =============================================================================
echo ""
echo -e "${CYAN}[4/6] Generowanie sekretow...${NC}"

REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
POSTGRES_NOCODB_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
NC_JWT_SECRET=$(uuidgen)
MINIO_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')

echo -e "${GREEN}[OK]${NC} Sekrety wygenerowane"

# =============================================================================
# 5. PODMIANA WARTOSCI W .env
# =============================================================================
echo ""
echo -e "${CYAN}[5/6] Zapisywanie konfiguracji do .env...${NC}"

# Funkcja do bezpiecznej podmiany (escape specjalnych znakow)
safe_replace() {
    local search="$1"
    local replace="$2"
    local file="$3"
    replace=$(printf '%s\n' "$replace" | sed 's/[&/\]/\\&/g')
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|${search}|${replace}|g" "$file"
    else
        sed -i "s|${search}|${replace}|g" "$file"
    fi
}

# Domeny
safe_replace "DOMAIN=twoja-domena.pl" "DOMAIN=${BASE_DOMAIN}" .env
safe_replace 'NOCODB_DOMAIN=nocodb.${DOMAIN}' "NOCODB_DOMAIN=${NOCODB_DOMAIN}" .env
safe_replace 'MINIO_DOMAIN=minio.${DOMAIN}' "MINIO_DOMAIN=${MINIO_DOMAIN}" .env

# Sekrety
safe_replace "REDIS_PASSWORD=WPISZ_SILNE_HASLO_REDIS" "REDIS_PASSWORD=${REDIS_PASSWORD}" .env
safe_replace "POSTGRES_NOCODB_PASSWORD=WPISZ_HASLO_POSTGRES" "POSTGRES_NOCODB_PASSWORD=${POSTGRES_NOCODB_PASSWORD}" .env
safe_replace "NC_JWT_SECRET=WYGENERUJ_UUID" "NC_JWT_SECRET=${NC_JWT_SECRET}" .env
safe_replace "MINIO_ROOT_PASSWORD=WPISZ_HASLO_MINIO" "MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}" .env

echo -e "${GREEN}[OK]${NC} Konfiguracja zapisana"

# =============================================================================
# 6. PODSUMOWANIE I ZAPIS SEKRETOW
# =============================================================================
echo ""
echo -e "${YELLOW}=========================================="
echo "  WYGENEROWANE SEKRETY - ZAPISZ JE!"
echo -e "==========================================${NC}"
echo ""
echo "Domeny:"
echo -e "  NOCODB_DOMAIN: ${GREEN}${NOCODB_DOMAIN}${NC}"
echo -e "  MINIO_DOMAIN:  ${GREEN}${MINIO_DOMAIN}${NC}"
echo ""
echo "Sekrety (zapisane w .env):"
echo "  REDIS_PASSWORD:           ${REDIS_PASSWORD:0:20}..."
echo "  POSTGRES_NOCODB_PASSWORD: ${POSTGRES_NOCODB_PASSWORD:0:20}..."
echo "  NC_JWT_SECRET:            ${NC_JWT_SECRET}"
echo "  MINIO_ROOT_PASSWORD:      ${MINIO_ROOT_PASSWORD:0:20}..."
echo ""

# Opcjonalnie zapisz do pliku secrets.txt
read -p "Czy zapisac pelne sekrety do pliku secrets.txt? [t/N]: " SAVE_SECRETS
SAVE_SECRETS=${SAVE_SECRETS:-N}

if [[ "$SAVE_SECRETS" =~ ^[Tt]$ ]]; then
    cat > secrets.txt << EOF
# Wygenerowane sekrety - $(date)
# UWAGA: Przechowuj ten plik bezpiecznie!

NOCODB_DOMAIN=${NOCODB_DOMAIN}
MINIO_DOMAIN=${MINIO_DOMAIN}

REDIS_PASSWORD=${REDIS_PASSWORD}
POSTGRES_NOCODB_PASSWORD=${POSTGRES_NOCODB_PASSWORD}
NC_JWT_SECRET=${NC_JWT_SECRET}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
EOF
    chmod 600 secrets.txt
    echo -e "${GREEN}[OK]${NC} Sekrety zapisane w secrets.txt (chmod 600)"
fi

# Uruchomienie setup.sh
echo ""
echo -e "${CYAN}Uruchamianie setup.sh...${NC}"
echo ""

./setup.sh

echo ""
echo -e "${GREEN}=========================================="
echo "  INICJALIZACJA ZAKONCZONA POMYSLNIE!"
echo -e "==========================================${NC}"
echo ""
echo "Nastepne kroki:"
echo "  1. Skonfiguruj rekordy DNS A:"
echo "     - ${NOCODB_DOMAIN} -> IP_SERWERA"
echo "     - ${MINIO_DOMAIN} -> IP_SERWERA"
echo "     - api.${MINIO_DOMAIN} -> IP_SERWERA (opcjonalnie dla S3 API)"
echo "  2. Uruchom stack: docker compose up -d"
echo "  3. Poczekaj na wygenerowanie certyfikatow SSL (~1-2 min)"
echo "  4. Sprawdz logi: docker compose logs -f"
echo ""
echo -e "Adresy aplikacji:"
echo -e "  NocoDB: ${GREEN}https://${NOCODB_DOMAIN}${NC}"
echo -e "  MinIO:  ${GREEN}https://${MINIO_DOMAIN}${NC}"
echo ""
