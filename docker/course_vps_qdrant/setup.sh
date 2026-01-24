#!/bin/bash
# =============================================================================
# SETUP SCRIPT - QDRANT VECTOR DATABASE (VPS)
# =============================================================================
# Ten skrypt przygotowuje srodowisko do uruchomienia stacka Docker
# =============================================================================

set -e

echo "=========================================="
echo "  SETUP - Qdrant Vector Database Stack"
echo "=========================================="
echo ""

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Sprawdz czy .env istnieje
if [ ! -f .env ]; then
    echo -e "${YELLOW}Plik .env nie istnieje.${NC}"
    echo "Kopiuje .env.example do .env..."
    cp .env.example .env
    echo ""
    echo -e "${RED}WAZNE: Edytuj plik .env i uzupelnij swoje dane!${NC}"
    echo ""
    echo "Przykladowa komenda do generowania klucza API:"
    echo "  openssl rand -base64 32"
    echo ""
    exit 1
fi

# 2. Sprawdz czy .env ma placeholdery
if grep -v '^[[:space:]]*#' .env | grep -q "WPISZ_\|WYGENERUJ_\|twoja-domena.pl"; then
    echo -e "${RED}BLAD: Plik .env zawiera nieuzupelnione wartosci!${NC}"
    echo ""
    grep -n "WPISZ_\|WYGENERUJ_\|twoja-domena.pl" .env | grep -v '^[0-9]*:[[:space:]]*#' || true
    echo ""
    exit 1
fi

echo -e "${GREEN}[OK]${NC} Plik .env jest skonfigurowany"

# 3. Utworz strukture katalogow
echo "Tworzenie struktury katalogow..."

mkdir -p volumes/qdrant_storage
mkdir -p volumes/caddy_data
mkdir -p volumes/caddy_config

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
source .env
echo -e "  Qdrant: https://${QDRANT_DOMAIN}"
echo ""
