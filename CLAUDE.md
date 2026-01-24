# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Opis projektu

Repozytorium z konfiguracjami Docker do kursu z automatyzacji. Zawiera dwie wersje stacka:
- **course_local_stack/** - wersja do nauki na lokalnej maszynie
- **course_vps_stack/** - wersja produkcyjna na serwer VPS

## Struktura repozytorium

```
.
├── course_local_stack/       # Wersja lokalna (bez SSL, localhost)
│   ├── init_local_stack.sh   # Skrypt inicjalizacji
│   ├── setup.sh              # Przygotowanie katalogów
│   ├── docker-compose.yml
│   └── .env.example
│
└── course_vps_stack/         # Wersja VPS (Caddy + SSL)
    ├── init.sh               # Skrypt inicjalizacji z konfiguracją domen
    ├── setup.sh              # Przygotowanie katalogów i sieci
    ├── docker-compose.yml
    ├── .env.example
    └── caddy/Caddyfile
```

## Architektura stacka

```
[Caddy - tylko VPS]
    ├── n8n (główna instancja UI)
    ├── n8n-worker (przetwarza kolejkę)
    ├── n8n-webhook (odbiera webhooki)
    ├── NocoDB (no-code database)
    ├── MinIO Console (S3 storage)
    └── Qdrant (vector database)

PostgreSQL ← n8n, NocoDB
Redis ← n8n (kolejki), NocoDB (cache)
MinIO ← NocoDB (pliki)
Qdrant ← n8n (embeddings, RAG)
```

n8n używa wzorca YAML anchor (`x-n8n-shared`) dla współdzielonej konfiguracji między instancjami.

## Komendy

```bash
# === LOCAL STACK ===
cd course_local_stack
./init_local_stack.sh        # Inicjalizacja (opcjonalne silne hasła)
docker compose up -d

# === VPS STACK ===
cd course_vps_stack
./init.sh                    # Inicjalizacja (konfiguracja domen + generowanie haseł)
docker compose up -d

# === Wspólne ===
docker compose logs -f [nazwa-uslugi]
docker compose pull && docker compose up -d
docker compose exec pg_database pg_dumpall -U nocodb > backup.sql
```

## Różnice między stackami

| Cecha | Local | VPS |
|-------|-------|-----|
| Reverse proxy | Brak | Caddy |
| SSL | Brak | Automatyczne (Let's Encrypt) |
| Hasła | Domyślne (opcjonalnie silne) | Silne (wymagane) |
| Domeny | localhost | Wymagane subdomeny |
| Sieć Docker | bridge | external (caddy) |

## Usługi i porty

| Usługa | Port | Local | VPS |
|--------|------|-------|-----|
| n8n | 5678 | localhost:5678 | n8n.DOMAIN |
| nocodb | 8080 | localhost:8080 | nocodb.DOMAIN |
| minio console | 9001 | localhost:9001 | minio.DOMAIN |
| minio API | 9000 | localhost:9000 | api.minio.DOMAIN |
| qdrant | 6333 | localhost:6333 | qdrant.DOMAIN |
| pg_database | 5432 | - | - |
| redis | 6379 | - | - |
| caddy | 80, 443 | - | tak |

## Konfiguracja

Pliki `.env.example` zawierają wszystkie zmienne:
- **Local**: domyślne wartości, opcjonalne generowanie przez `openssl rand -base64 32`
- **VPS**: placeholdery, wymagane generowanie przez `init.sh`

Redis używa osobnych baz: `/0` dla NocoDB, `/14` dla n8n queue.
