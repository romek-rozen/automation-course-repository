#!/bin/bash
# =============================================================================
# INIT SCRIPT - PELNA AUTOMATYZACJA KONFIGURACJI
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
echo "  INIT - Automatyczna konfiguracja stacka"
echo -e "==========================================${NC}"
echo ""

# =============================================================================
# 1. SPRAWDZENIE WYMAGAN SYSTEMOWYCH
# =============================================================================
echo -e "${CYAN}[1/7] Sprawdzanie wymagan systemowych...${NC}"

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
echo -e "${CYAN}[2/7] Przygotowanie pliku .env...${NC}"

if [ -f .env ]; then
    # Sprawdz czy .env ma placeholdery (czyli nie byl jeszcze skonfigurowany)
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
echo -e "${CYAN}[3/7] Konfiguracja domen...${NC}"
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
DEFAULT_N8N="n8n.${BASE_DOMAIN}"
DEFAULT_NOCODB="nocodb.${BASE_DOMAIN}"
DEFAULT_MINIO="minio.${BASE_DOMAIN}"
DEFAULT_QDRANT="qdrant.${BASE_DOMAIN}"

echo ""
echo "Domyslne subdomeny:"
echo -e "  - n8n:    ${GREEN}${DEFAULT_N8N}${NC}"
echo -e "  - nocodb: ${GREEN}${DEFAULT_NOCODB}${NC}"
echo -e "  - minio:  ${GREEN}${DEFAULT_MINIO}${NC}"
echo -e "  - qdrant: ${GREEN}${DEFAULT_QDRANT}${NC}"
echo ""

read -p "Uzyc domyslnych subdomen? [T/n]: " USE_DEFAULTS
USE_DEFAULTS=${USE_DEFAULTS:-T}

if [[ "$USE_DEFAULTS" =~ ^[Tt]$ ]]; then
    N8N_DOMAIN="$DEFAULT_N8N"
    NOCODB_DOMAIN="$DEFAULT_NOCODB"
    MINIO_DOMAIN="$DEFAULT_MINIO"
    QDRANT_DOMAIN="$DEFAULT_QDRANT"
else
    echo ""
    echo "Podaj pelna domene dla kazdej uslugi (Enter = domyslna):"
    echo ""

    read -p "Domena dla n8n [${DEFAULT_N8N}]: " N8N_DOMAIN
    N8N_DOMAIN=${N8N_DOMAIN:-$DEFAULT_N8N}

    read -p "Domena dla nocodb [${DEFAULT_NOCODB}]: " NOCODB_DOMAIN
    NOCODB_DOMAIN=${NOCODB_DOMAIN:-$DEFAULT_NOCODB}

    read -p "Domena dla minio [${DEFAULT_MINIO}]: " MINIO_DOMAIN
    MINIO_DOMAIN=${MINIO_DOMAIN:-$DEFAULT_MINIO}

    read -p "Domena dla qdrant [${DEFAULT_QDRANT}]: " QDRANT_DOMAIN
    QDRANT_DOMAIN=${QDRANT_DOMAIN:-$DEFAULT_QDRANT}
fi

echo ""
echo -e "${GREEN}[OK]${NC} Domeny skonfigurowane"

# =============================================================================
# 4. GENEROWANIE SEKRETOW
# =============================================================================
echo ""
echo -e "${CYAN}[4/7] Generowanie sekretow...${NC}"

# URL-safe hasla (hex) - uzywane w connection stringach
REDIS_PASSWORD=$(openssl rand -hex 32)
POSTGRES_PASSWORD=$(openssl rand -hex 32)
POSTGRES_NOCODB_PASSWORD=$(openssl rand -hex 32)
POSTGRES_N8N_PASSWORD=$(openssl rand -hex 32)
MINIO_ROOT_PASSWORD=$(openssl rand -hex 32)

# Klucze szyfrujace - base64 OK (nie uzywane w URL)
N8N_ENCRYPTION_KEY=$(openssl rand -base64 32 | tr -d '\n')
N8N_JWT_SECRET=$(openssl rand -base64 32 | tr -d '\n')
NC_JWT_SECRET=$(uuidgen)
QDRANT_API_KEY=$(openssl rand -hex 32)

echo -e "${GREEN}[OK]${NC} Sekrety wygenerowane"

# =============================================================================
# 5. PODMIANA WARTOSCI W .env
# =============================================================================
echo ""
echo -e "${CYAN}[5/7] Zapisywanie konfiguracji do .env...${NC}"

# Wykryj system operacyjny dla kompatybilnosci sed
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE="sed -i ''"
else
    SED_INPLACE="sed -i"
fi

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

# Domeny
safe_replace "DOMAIN=twoja-domena.pl" "DOMAIN=${BASE_DOMAIN}" .env
safe_replace 'N8N_DOMAIN=n8n.${DOMAIN}' "N8N_DOMAIN=${N8N_DOMAIN}" .env
safe_replace 'NOCODB_DOMAIN=nocodb.${DOMAIN}' "NOCODB_DOMAIN=${NOCODB_DOMAIN}" .env
safe_replace 'MINIO_DOMAIN=minio.${DOMAIN}' "MINIO_DOMAIN=${MINIO_DOMAIN}" .env
safe_replace 'QDRANT_DOMAIN=qdrant.${DOMAIN}' "QDRANT_DOMAIN=${QDRANT_DOMAIN}" .env

# Sekrety
safe_replace "REDIS_PASSWORD=WPISZ_SILNE_HASLO_REDIS" "REDIS_PASSWORD=${REDIS_PASSWORD}" .env
safe_replace "POSTGRES_PASSWORD=WPISZ_SILNE_HASLO_POSTGRES_ADMIN" "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" .env
safe_replace "POSTGRES_NOCODB_PASSWORD=WPISZ_HASLO_NOCODB_POSTGRES" "POSTGRES_NOCODB_PASSWORD=${POSTGRES_NOCODB_PASSWORD}" .env
safe_replace "POSTGRES_N8N_PASSWORD=WPISZ_HASLO_N8N_POSTGRES" "POSTGRES_N8N_PASSWORD=${POSTGRES_N8N_PASSWORD}" .env
safe_replace "N8N_ENCRYPTION_KEY=WYGENERUJ_KLUCZ_32_ZNAKI" "N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}" .env
safe_replace "N8N_USER_MANAGEMENT_JWT_SECRET=WYGENERUJ_JWT_SECRET" "N8N_USER_MANAGEMENT_JWT_SECRET=${N8N_JWT_SECRET}" .env
safe_replace "NC_JWT_SECRET=WYGENERUJ_UUID" "NC_JWT_SECRET=${NC_JWT_SECRET}" .env
safe_replace "MINIO_ROOT_PASSWORD=WPISZ_HASLO_MINIO" "MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}" .env
safe_replace "QDRANT_API_KEY=" "QDRANT_API_KEY=${QDRANT_API_KEY}" .env

echo -e "${GREEN}[OK]${NC} Konfiguracja zapisana"

# =============================================================================
# 6. PODSUMOWANIE SEKRETOW
# =============================================================================
echo ""
echo -e "${CYAN}[6/7] Podsumowanie konfiguracji...${NC}"
echo ""
echo -e "${YELLOW}=========================================="
echo "  WYGENEROWANE SEKRETY - ZAPISZ JE!"
echo -e "==========================================${NC}"
echo ""
echo "Domeny:"
echo -e "  DOMAIN:        ${GREEN}${BASE_DOMAIN}${NC}"
echo -e "  N8N_DOMAIN:    ${GREEN}${N8N_DOMAIN}${NC}"
echo -e "  NOCODB_DOMAIN: ${GREEN}${NOCODB_DOMAIN}${NC}"
echo -e "  MINIO_DOMAIN:  ${GREEN}${MINIO_DOMAIN}${NC}"
echo -e "  QDRANT_DOMAIN: ${GREEN}${QDRANT_DOMAIN}${NC}"
echo ""
echo "Sekrety (zapisane w .env):"
echo "  REDIS_PASSWORD:         ${REDIS_PASSWORD:0:20}..."
echo "  POSTGRES_PASSWORD:      ${POSTGRES_PASSWORD:0:20}..."
echo "  POSTGRES_NOCODB_PASSWORD: ${POSTGRES_NOCODB_PASSWORD:0:20}..."
echo "  POSTGRES_N8N_PASSWORD:  ${POSTGRES_N8N_PASSWORD:0:20}..."
echo "  N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY:0:20}..."
echo "  N8N_JWT_SECRET:     ${N8N_JWT_SECRET:0:20}..."
echo "  NC_JWT_SECRET:      ${NC_JWT_SECRET}"
echo "  MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:0:20}..."
echo "  QDRANT_API_KEY:     ${QDRANT_API_KEY:0:20}..."
echo ""

# Opcjonalnie zapisz do pliku secrets.txt
read -p "Czy zapisac pelne sekrety do pliku secrets.txt? [t/N]: " SAVE_SECRETS
SAVE_SECRETS=${SAVE_SECRETS:-N}

if [[ "$SAVE_SECRETS" =~ ^[Tt]$ ]]; then
    cat > secrets.txt << EOF
# Wygenerowane sekrety - $(date)
# UWAGA: Przechowuj ten plik bezpiecznie!

REDIS_PASSWORD=${REDIS_PASSWORD}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_NOCODB_PASSWORD=${POSTGRES_NOCODB_PASSWORD}
POSTGRES_N8N_PASSWORD=${POSTGRES_N8N_PASSWORD}
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
N8N_USER_MANAGEMENT_JWT_SECRET=${N8N_JWT_SECRET}
NC_JWT_SECRET=${NC_JWT_SECRET}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
QDRANT_API_KEY=${QDRANT_API_KEY}
EOF
    chmod 600 secrets.txt
    echo -e "${GREEN}[OK]${NC} Sekrety zapisane w secrets.txt (chmod 600)"
fi

# =============================================================================
# 7. URUCHOMIENIE SETUP.SH
# =============================================================================
echo ""
echo -e "${CYAN}[7/7] Uruchamianie setup.sh...${NC}"
echo ""

./setup.sh

echo ""
echo -e "${GREEN}=========================================="
echo "  INICJALIZACJA ZAKONCZONA POMYSLNIE!"
echo -e "==========================================${NC}"
echo ""
echo "Nastepne kroki:"
echo "  1. Skonfiguruj rekordy DNS dla subdomen"
echo "  2. Uruchom stack: docker compose up -d"
echo "  3. Poczekaj na wygenerowanie certyfikatow SSL"
echo "  4. Sprawdz logi: docker compose logs -f"
echo ""
