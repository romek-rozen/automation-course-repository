#!/bin/bash
# =============================================================================
# SETUP SCRIPT - SZABLON DO KURSU
# =============================================================================
# Ten skrypt przygotowuje srodowisko do uruchomienia stacka Docker
# =============================================================================

set -e

echo "=========================================="
echo "  SETUP - Przygotowanie srodowiska"
echo "=========================================="
echo ""

# Kolory dla komunikatow
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Sprawdz czy .env istnieje
if [ ! -f .env ]; then
    echo -e "${YELLOW}Plik .env nie istnieje.${NC}"
    echo "Kopiuje .env.example do .env..."
    cp .env.example .env
    echo ""
    echo -e "${RED}WAZNE: Edytuj plik .env i uzupelnij swoje dane!${NC}"
    echo ""
    echo "Wymagane kroki:"
    echo "  1. Otworz plik .env w edytorze"
    echo "  2. Zmien DOMAIN na swoja domene"
    echo "  3. Wygeneruj i wpisz wszystkie hasla"
    echo "  4. Uruchom ten skrypt ponownie"
    echo ""
    echo "Przykladowe komendy do generowania hasel:"
    echo "  openssl rand -base64 32    # dla kluczy szyfrowania"
    echo "  uuidgen                    # dla JWT secrets"
    echo ""
    exit 1
fi

# 2. Sprawdz czy .env ma placeholdery
if grep -q "WPISZ_\|WYGENERUJ_\|twoja-domena.pl" .env; then
    echo -e "${RED}BLAD: Plik .env zawiera nieuzupelnione wartosci!${NC}"
    echo ""
    echo "Znajdz i uzupelnij wszystkie linie zawierajace:"
    echo "  - WPISZ_..."
    echo "  - WYGENERUJ_..."
    echo "  - twoja-domena.pl"
    echo ""
    grep -n "WPISZ_\|WYGENERUJ_\|twoja-domena.pl" .env || true
    echo ""
    exit 1
fi

echo -e "${GREEN}[OK]${NC} Plik .env jest skonfigurowany"

# 3. Utworz strukture katalogow
echo "Tworzenie struktury katalogow..."

mkdir -p volumes/nocodb
mkdir -p volumes/n8n/data
mkdir -p volumes/n8n/local_files
mkdir -p volumes/caddy_data
mkdir -p volumes/caddy_config
mkdir -p volumes/redis_data
mkdir -p volumes/minio_data
mkdir -p volumes/qdrant_storage
mkdir -p volumes/mysql_data
mkdir -p volumes/db_data

echo -e "${GREEN}[OK]${NC} Katalogi utworzone"

# 4. Skopiuj Caddyfile
echo "Kopiowanie Caddyfile..."
cp caddy/Caddyfile volumes/caddy_config/Caddyfile

echo -e "${GREEN}[OK]${NC} Caddyfile skopiowany"

# 5. Utworz siec Docker jesli nie istnieje
echo "Sprawdzanie sieci Docker..."
if ! docker network inspect caddy >/dev/null 2>&1; then
    echo "Tworzenie sieci 'caddy'..."
    docker network create caddy
    echo -e "${GREEN}[OK]${NC} Siec 'caddy' utworzona"
else
    echo -e "${GREEN}[OK]${NC} Siec 'caddy' juz istnieje"
fi

# 6. Podsumowanie
echo ""
echo "=========================================="
echo -e "${GREEN}  SETUP ZAKONCZONY POMYSLNIE!${NC}"
echo "=========================================="
echo ""
echo "Nastepne kroki:"
echo "  1. Upewnij sie, ze Twoja domena wskazuje na ten serwer"
echo "  2. Uruchom stack: docker compose up -d"
echo "  3. Sprawdz logi: docker compose logs -f"
echo ""
echo "Adresy aplikacji (po uruchomieniu):"
source .env
echo "  - n8n:    https://n8n.${DOMAIN}"
echo "  - NocoDB: https://nocodb.${DOMAIN}"
echo "  - MinIO:  https://minio.${DOMAIN}"
echo "  - Qdrant: https://qdrant.${DOMAIN}"
echo ""
