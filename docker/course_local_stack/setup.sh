#!/bin/bash
# =============================================================================
# SETUP SCRIPT - WERSJA LOKALNA
# =============================================================================
# Przygotowuje srodowisko do uruchomienia stacka Docker.
# Uruchom przed pierwszym 'docker compose up -d'
# =============================================================================

set -e

echo "=========================================="
echo "  SETUP - Przygotowanie srodowiska"
echo "=========================================="
echo ""

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Sprawdz czy .env istnieje
echo "[1/3] Sprawdzanie pliku .env..."

if [ ! -f .env ]; then
    echo -e "${YELLOW}Plik .env nie istnieje.${NC}"
    echo "Kopiuje .env.example do .env..."
    cp .env.example .env
    echo -e "${GREEN}[OK]${NC} Plik .env utworzony z domyslnymi wartosciami"
    echo ""
    echo -e "${YELLOW}INFO: Domyslne hasla sa wystarczajace do nauki.${NC}"
    echo "      Mozesz je zmienic edytujac plik .env"
else
    echo -e "${GREEN}[OK]${NC} Plik .env istnieje"
fi
echo ""

# 2. Utworz strukture katalogow
echo "[2/3] Tworzenie struktury katalogow..."

mkdir -p volumes/nocodb
mkdir -p volumes/n8n/data
mkdir -p volumes/n8n/local_files
mkdir -p volumes/redis_data
mkdir -p volumes/minio_data
mkdir -p volumes/qdrant_storage
mkdir -p volumes/db_data

echo -e "${GREEN}[OK]${NC} Katalogi utworzone:"
echo "      volumes/nocodb"
echo "      volumes/n8n/data"
echo "      volumes/n8n/local_files"
echo "      volumes/redis_data"
echo "      volumes/minio_data"
echo "      volumes/qdrant_storage"
echo "      volumes/db_data"
echo ""

# 3. Podsumowanie
echo "[3/3] Podsumowanie"
echo ""
echo "=========================================="
echo -e "${GREEN}  SETUP ZAKONCZONY POMYSLNIE!${NC}"
echo "=========================================="
echo ""
echo "Nastepne kroki:"
echo "  1. Uruchom stack:  docker compose up -d"
echo "  2. Poczekaj ~30-60 sekund na uruchomienie uslug"
echo "  3. Sprawdz status: docker compose ps"
echo "  4. Sprawdz logi:   docker compose logs -f"
echo ""
echo "Adresy aplikacji (po uruchomieniu):"
echo "  - n8n:             http://localhost:5678"
echo "  - NocoDB:          http://localhost:8080"
echo "  - MinIO Console:   http://localhost:9001"
echo "  - Qdrant Dashboard: http://localhost:6333/dashboard"
echo ""
echo "Dane logowania MinIO:"
echo "  - User: minioadmin"
echo "  - Pass: (zobacz MINIO_ROOT_PASSWORD w .env)"
echo ""
