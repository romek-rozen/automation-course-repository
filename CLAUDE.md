# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Opis projektu

Szablon Docker stack do kursu z automatyzacji. Zawiera gotowy zestaw usług do wdrożenia na VPS.

## Architektura stacka

```
Caddy (reverse proxy + SSL)
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
# Inicjalizacja (tworzy volumes/, sieć caddy, Caddyfile)
./setup.sh

# Uruchomienie
docker compose up -d

# Logi
docker compose logs -f [nazwa-uslugi]

# Aktualizacja
docker compose pull && docker compose up -d

# Backup PostgreSQL
docker compose exec pg_database pg_dumpall -U nocodb > backup_postgres.sql

# Walidacja compose
docker compose config
```

## Konfiguracja

Plik `.env.example` zawiera wszystkie zmienne. Wartości do wygenerowania:
- `openssl rand -base64 32` - klucze szyfrowania
- `uuidgen` - JWT secrets

Redis używa osobnych baz: `/0` dla NocoDB, `/1` dla n8n.

## Usługi i porty wewnętrzne

| Usługa | Port |
|--------|------|
| n8n | 5678 |
| nocodb | 8080 |
| pg_database | 5432 |
| redis | 6379 |
| minio | 9000 (API), 9001 (Console) |
| qdrant | 6333 (REST), 6334 (gRPC) |
| caddy | 80, 443 |

## Sieć Docker

Wszystkie usługi używają zewnętrznej sieci `caddy` (tworzona przez setup.sh).
