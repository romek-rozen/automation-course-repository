# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Opis projektu

Repozytorium z konfiguracjami Docker do kursu z automatyzacji. Zawiera trzy wersje stacka:
- **course_local_stack/** - wersja do nauki na lokalnej maszynie
- **course_vps_stack/** - pelna wersja produkcyjna na serwer VPS
- **course_vps_n8n_with_workers/** - uproszczony stack VPS (tylko n8n + workers)

## Struktura repozytorium

```
.
├── course_local_stack/            # Wersja lokalna (bez SSL, localhost)
│   ├── init_local_stack.sh        # Skrypt inicjalizacji
│   ├── init-data.sh               # Skrypt PostgreSQL (tworzy bazy i userow)
│   ├── setup.sh                   # Przygotowanie katalogow
│   ├── docker-compose.yml
│   └── .env.example
│
├── course_vps_stack/              # Pelna wersja VPS (Caddy + SSL)
│   ├── init.sh                    # Skrypt inicjalizacji z konfiguracja domen
│   ├── init-data.sh               # Skrypt PostgreSQL (tworzy bazy i userow)
│   ├── setup.sh                   # Przygotowanie katalogow i sieci
│   ├── docker-compose.yml
│   ├── .env.example
│   └── caddy/Caddyfile
│
└── course_vps_n8n_with_workers/   # Uproszczony VPS (tylko n8n + workers)
    ├── init.sh                    # Skrypt inicjalizacji
    ├── setup.sh                   # Przygotowanie katalogow i sieci
    ├── docker-compose.yml         # 6 uslug (bez NocoDB, MinIO, Qdrant)
    ├── .env.example               # 4 sekrety
    └── caddy/Caddyfile            # Tylko routing n8n
```

## Architektura stacka

### Pelny stack (course_vps_stack)

```
[Caddy]
    ├── n8n (UI + API)
    ├── n8n-worker (przetwarza kolejke)
    ├── n8n-webhook (odbiera webhooki)
    ├── NocoDB (no-code database)
    ├── MinIO Console (S3 storage)
    └── Qdrant (vector database)

PostgreSQL ← n8n, NocoDB
Redis ← n8n (kolejki /14), NocoDB (cache /15)
MinIO ← NocoDB (pliki)
Qdrant ← n8n (embeddings, RAG)
```

### Uproszczony stack (course_vps_n8n_with_workers)

```
[Caddy]
    └── n8n (UI + API)
        ├── n8n-worker (przetwarza kolejke)
        └── n8n-webhook (odbiera webhooki)

PostgreSQL ← n8n
Redis ← n8n (kolejki Bull /14)
```

n8n uzywa wzorca YAML anchor (`x-n8n-shared`) dla wspoldzielonej konfiguracji miedzy instancjami.

## Komendy

```bash
# === LOCAL STACK ===
cd course_local_stack
./init_local_stack.sh        # Inicjalizacja (opcjonalne silne hasla)
docker compose up -d

# === VPS STACK (pelny) ===
cd course_vps_stack
./init.sh                    # Inicjalizacja (konfiguracja domen + generowanie hasel)
docker compose up -d

# === VPS N8N WITH WORKERS (uproszczony) ===
cd course_vps_n8n_with_workers
./init.sh                    # Inicjalizacja (1 domena + 4 sekrety)
docker compose up -d
docker compose up -d --scale n8n-worker=3  # Skalowanie workerow

# === Wspolne ===
docker compose logs -f [nazwa-uslugi]
docker compose pull && docker compose up -d
docker compose exec pg_database pg_dump -U n8n n8n_db > backup.sql
```

## Roznice miedzy stackami

| Cecha | Local | VPS (pelny) | VPS n8n+workers |
|-------|-------|-------------|-----------------|
| Reverse proxy | Brak | Caddy | Caddy |
| SSL | Brak | Let's Encrypt | Let's Encrypt |
| Hasla | Domyslne | 8 sekretow | 4 sekrety |
| Domeny | localhost | 5 subdomen | 1 subdomena |
| Uslugi | 9 | 9 | 6 |
| RAM | ~4GB | ~6GB | ~2GB |
| NocoDB | Tak | Tak | Nie |
| MinIO | Tak | Tak | Nie |
| Qdrant | Tak | Tak | Nie |

## Uslugi i porty

| Usluga | Port | Local | VPS (pelny) | VPS n8n+workers |
|--------|------|-------|-------------|-----------------|
| n8n | 5678 | localhost:5678 | n8n.DOMAIN | n8n.DOMAIN |
| nocodb | 8080 | localhost:8080 | nocodb.DOMAIN | - |
| minio console | 9001 | localhost:9001 | minio.DOMAIN | - |
| minio API | 9000 | localhost:9000 | api.minio.DOMAIN | - |
| qdrant | 6333 | localhost:6333 | qdrant.DOMAIN | - |
| pg_database | 5432 | - | - | - |
| redis | 6379 | - | - | - |
| caddy | 80, 443 | - | tak | tak |

## Konfiguracja

Pliki `.env.example` zawierają wszystkie zmienne:
- **Local**: domyślne wartości, opcjonalne generowanie przez `openssl rand -base64 32`
- **VPS**: placeholdery, wymagane generowanie przez `init.sh`

Redis używa osobnych baz: `/15` dla NocoDB, `/14` dla n8n queue.

## PostgreSQL - struktura użytkowników

```
PostgreSQL
├── postgres (SUPERUSER) ← tylko do administracji i backupów
├── nocodb → nocodb_db   ← zwykły user z dostępem tylko do swojej bazy
└── n8n → n8n_db         ← zwykły user z dostępem tylko do swojej bazy
```

Skrypt `init-data.sh` tworzy bazy i użytkowników przy pierwszym uruchomieniu PostgreSQL.
