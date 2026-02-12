#!/bin/bash
# =============================================================================
# INIT SCRIPT - N8N WITHOUT WORKERS (VPS)
# =============================================================================
# Ten skrypt automatycznie:
# - Sprawdza wymagania systemowe
# - Konfiguruje domene (interaktywnie)
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
echo "  INIT - n8n without Workers Stack"
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

# Domyslna subdomena n8n
DEFAULT_N8N="n8n.${BASE_DOMAIN}"

echo ""
echo "Domyslna subdomena:"
echo -e "  - n8n: ${GREEN}${DEFAULT_N8N}${NC}"
echo ""

read -p "Uzyc domyslnej subdomeny? [T/n]: " USE_DEFAULT
USE_DEFAULT=${USE_DEFAULT:-T}

if [[ "$USE_DEFAULT" =~ ^[Tt]$ ]]; then
    N8N_DOMAIN="$DEFAULT_N8N"
else
    read -p "Podaj pelna domene dla n8n [${DEFAULT_N8N}]: " N8N_DOMAIN
    N8N_DOMAIN=${N8N_DOMAIN:-$DEFAULT_N8N}
fi

echo ""
echo -e "${GREEN}[OK]${NC} Domena skonfigurowana: ${N8N_DOMAIN}"

# =============================================================================
# 4. GENEROWANIE SEKRETOW
# =============================================================================
echo ""
echo -e "${CYAN}[4/6] Generowanie sekretow...${NC}"

# URL-safe hasla (hex) - uzywane w connection stringach
REDIS_PASSWORD=$(openssl rand -hex 32)
POSTGRES_PASSWORD=$(openssl rand -hex 32)
POSTGRES_N8N_PASSWORD=$(openssl rand -hex 32)

# Klucze szyfrujace - base64 OK (nie uzywane w URL)
N8N_ENCRYPTION_KEY=$(openssl rand -base64 32 | tr -d '\n')
N8N_JWT_SECRET=$(openssl rand -base64 32 | tr -d '\n')

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
safe_replace 'N8N_DOMAIN=n8n.${DOMAIN}' "N8N_DOMAIN=${N8N_DOMAIN}" .env

# Sekrety
safe_replace "REDIS_PASSWORD=WPISZ_SILNE_HASLO_REDIS" "REDIS_PASSWORD=${REDIS_PASSWORD}" .env
safe_replace "POSTGRES_PASSWORD=WPISZ_HASLO_POSTGRES_ADMIN" "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" .env
safe_replace "POSTGRES_N8N_PASSWORD=WPISZ_HASLO_POSTGRES_N8N" "POSTGRES_N8N_PASSWORD=${POSTGRES_N8N_PASSWORD}" .env
safe_replace "N8N_ENCRYPTION_KEY=WYGENERUJ_KLUCZ_32_ZNAKI" "N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}" .env
safe_replace "N8N_USER_MANAGEMENT_JWT_SECRET=WYGENERUJ_JWT_SECRET" "N8N_USER_MANAGEMENT_JWT_SECRET=${N8N_JWT_SECRET}" .env

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
echo -e "  N8N_DOMAIN: ${GREEN}${N8N_DOMAIN}${NC}"
echo ""
echo "Sekrety (zapisane w .env):"
echo "  REDIS_PASSWORD:         ${REDIS_PASSWORD:0:20}..."
echo "  POSTGRES_PASSWORD:      ${POSTGRES_PASSWORD:0:20}... (superuser)"
echo "  POSTGRES_N8N_PASSWORD:  ${POSTGRES_N8N_PASSWORD:0:20}..."
echo "  N8N_ENCRYPTION_KEY:     ${N8N_ENCRYPTION_KEY:0:20}..."
echo "  N8N_JWT_SECRET:         ${N8N_JWT_SECRET:0:20}..."
echo ""

# Opcjonalnie zapisz do pliku secrets.txt
read -p "Czy zapisac pelne sekrety do pliku secrets.txt? [t/N]: " SAVE_SECRETS
SAVE_SECRETS=${SAVE_SECRETS:-N}

if [[ "$SAVE_SECRETS" =~ ^[Tt]$ ]]; then
    cat > secrets.txt << EOF
# Wygenerowane sekrety - $(date)
# UWAGA: Przechowuj ten plik bezpiecznie!

N8N_DOMAIN=${N8N_DOMAIN}

REDIS_PASSWORD=${REDIS_PASSWORD}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_N8N_PASSWORD=${POSTGRES_N8N_PASSWORD}
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
N8N_USER_MANAGEMENT_JWT_SECRET=${N8N_JWT_SECRET}
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
echo "  1. Skonfiguruj rekord DNS A: ${N8N_DOMAIN} -> IP_SERWERA"
echo "  2. Uruchom stack: docker compose up -d"
echo "  3. Poczekaj na wygenerowanie certyfikatu SSL (~1-2 min)"
echo "  4. Sprawdz logi: docker compose logs -f"
echo ""
echo -e "Adres n8n: ${GREEN}https://${N8N_DOMAIN}${NC}"
echo ""
