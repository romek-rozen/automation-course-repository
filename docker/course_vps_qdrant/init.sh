#!/bin/bash
# =============================================================================
# INIT SCRIPT - QDRANT VECTOR DATABASE (VPS)
# =============================================================================
# Ten skrypt automatycznie:
# - Sprawdza wymagania systemowe
# - Konfiguruje domene (interaktywnie)
# - Generuje klucz API
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
echo "  INIT - Qdrant Vector Database Stack"
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

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo -e "${RED}BLAD: Brakujace zaleznosci:${NC}"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo "Zainstaluj brakujace pakiety i uruchom skrypt ponownie."
    echo "Na Ubuntu/Debian: sudo apt install docker.io docker-compose-plugin"
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
# 3. KONFIGURACJA DOMENY (INTERAKTYWNA)
# =============================================================================
echo ""
echo -e "${CYAN}[3/6] Konfiguracja domeny...${NC}"
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

# Domyslna subdomena qdrant
DEFAULT_QDRANT="qdrant.${BASE_DOMAIN}"

echo ""
echo "Domyslna subdomena:"
echo -e "  - qdrant: ${GREEN}${DEFAULT_QDRANT}${NC}"
echo ""

read -p "Uzyc domyslnej subdomeny? [T/n]: " USE_DEFAULT
USE_DEFAULT=${USE_DEFAULT:-T}

if [[ "$USE_DEFAULT" =~ ^[Tt]$ ]]; then
    QDRANT_DOMAIN="$DEFAULT_QDRANT"
else
    read -p "Podaj pelna domene dla qdrant [${DEFAULT_QDRANT}]: " QDRANT_DOMAIN
    QDRANT_DOMAIN=${QDRANT_DOMAIN:-$DEFAULT_QDRANT}
fi

echo ""
echo -e "${GREEN}[OK]${NC} Domena skonfigurowana: ${QDRANT_DOMAIN}"

# =============================================================================
# 4. GENEROWANIE SEKRETOW
# =============================================================================
echo ""
echo -e "${CYAN}[4/6] Generowanie sekretow...${NC}"

QDRANT_API_KEY=$(openssl rand -base64 32 | tr -d '\n')

echo -e "${GREEN}[OK]${NC} Klucz API wygenerowany"

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
safe_replace 'QDRANT_DOMAIN=qdrant.${DOMAIN}' "QDRANT_DOMAIN=${QDRANT_DOMAIN}" .env

# Sekrety
safe_replace "QDRANT_API_KEY=WYGENERUJ_API_KEY" "QDRANT_API_KEY=${QDRANT_API_KEY}" .env

echo -e "${GREEN}[OK]${NC} Konfiguracja zapisana"

# =============================================================================
# 6. PODSUMOWANIE I ZAPIS SEKRETOW
# =============================================================================
echo ""
echo -e "${YELLOW}=========================================="
echo "  WYGENEROWANE SEKRETY - ZAPISZ JE!"
echo -e "==========================================${NC}"
echo ""
echo "Domena:"
echo -e "  QDRANT_DOMAIN: ${GREEN}${QDRANT_DOMAIN}${NC}"
echo ""
echo "Sekrety (zapisane w .env):"
echo "  QDRANT_API_KEY: ${QDRANT_API_KEY:0:20}..."
echo ""

# Opcjonalnie zapisz do pliku secrets.txt
read -p "Czy zapisac pelne sekrety do pliku secrets.txt? [t/N]: " SAVE_SECRETS
SAVE_SECRETS=${SAVE_SECRETS:-N}

if [[ "$SAVE_SECRETS" =~ ^[Tt]$ ]]; then
    cat > secrets.txt << EOF
# Wygenerowane sekrety - $(date)
# UWAGA: Przechowuj ten plik bezpiecznie!

QDRANT_DOMAIN=${QDRANT_DOMAIN}

QDRANT_API_KEY=${QDRANT_API_KEY}
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
echo "  1. Skonfiguruj rekord DNS A: ${QDRANT_DOMAIN} -> IP_SERWERA"
echo "  2. Uruchom stack: docker compose up -d"
echo "  3. Poczekaj na wygenerowanie certyfikatu SSL (~1-2 min)"
echo "  4. Sprawdz logi: docker compose logs -f"
echo ""
echo -e "Adres Qdrant: ${GREEN}https://${QDRANT_DOMAIN}${NC}"
echo ""
echo "Przyklad uzycia (curl):"
echo "  curl -H 'api-key: \${QDRANT_API_KEY}' https://${QDRANT_DOMAIN}/collections"
echo ""
