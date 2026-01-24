# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Opis projektu

Repozytorium z konfiguracjami Docker do kursu z automatyzacji. Zawiera cztery wersje stacka:
- **course_local_stack/** - wersja do nauki na lokalnej maszynie
- **course_vps_stack/** - pelna wersja produkcyjna na serwer VPS
- **course_vps_n8n_with_workers/** - uproszczony stack VPS (tylko n8n + workers)
- **course_vps_nocodb/** - uproszczony stack VPS (tylko NocoDB + MinIO)

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
├── course_vps_n8n_with_workers/   # Uproszczony VPS (tylko n8n + workers)
│   ├── init.sh                    # Skrypt inicjalizacji
│   ├── init-data.sh               # Skrypt PostgreSQL (tworzy baze i usera)
│   ├── setup.sh                   # Przygotowanie katalogow i sieci
│   ├── docker-compose.yml         # 6 uslug (bez NocoDB, MinIO, Qdrant)
│   ├── .env.example               # 5 sekretow
│   └── caddy/Caddyfile            # Tylko routing n8n
│
└── course_vps_nocodb/             # Uproszczony VPS (tylko NocoDB + MinIO)
    ├── init.sh                    # Skrypt inicjalizacji
    ├── init-data.sh               # Skrypt PostgreSQL (tworzy baze i usera)
    ├── setup.sh                   # Przygotowanie katalogow i sieci
    ├── docker-compose.yml         # 5 uslug (bez n8n, Qdrant)
    ├── .env.example               # 5 sekretow
    └── caddy/Caddyfile            # Routing nocodb + minio
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

### Uproszczony stack n8n (course_vps_n8n_with_workers)

```
[Caddy]
    └── n8n (UI + API)
        ├── n8n-worker (przetwarza kolejke)
        └── n8n-webhook (odbiera webhooki)

PostgreSQL ← n8n
Redis ← n8n (kolejki Bull /14)
```

n8n uzywa wzorca YAML anchor (`x-n8n-shared`) dla wspoldzielonej konfiguracji miedzy instancjami.

### Uproszczony stack NocoDB (course_vps_nocodb)

```
[Caddy]
    ├── NocoDB (no-code database)
    └── MinIO Console (S3 storage)

PostgreSQL ← NocoDB
Redis ← NocoDB (cache /15)
MinIO ← NocoDB (pliki/attachmenty)
```

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
./init.sh                    # Inicjalizacja (1 domena + 5 sekretow)
docker compose up -d
docker compose up -d --scale n8n-worker=3  # Skalowanie workerow

# === VPS NOCODB (uproszczony) ===
cd course_vps_nocodb
./init.sh                    # Inicjalizacja (2 domeny + 5 sekretow)
docker compose up -d

# === Wspolne ===
docker compose logs -f [nazwa-uslugi]
docker compose pull && docker compose up -d
docker compose exec pg_database pg_dump -U postgres n8n_db > backup.sql
```

## Roznice miedzy stackami

| Cecha | Local | VPS (pelny) | VPS n8n+workers | VPS nocodb |
|-------|-------|-------------|-----------------|------------|
| Reverse proxy | Brak | Caddy | Caddy | Caddy |
| SSL | Brak | Let's Encrypt | Let's Encrypt | Let's Encrypt |
| Hasla | Domyslne | 8 sekretow | 5 sekretow | 5 sekretow |
| Domeny | localhost | 5 subdomen | 1 subdomena | 2 subdomeny |
| Uslugi | 9 | 9 | 6 | 5 |
| RAM | ~4GB | ~6GB | ~2GB | ~2GB |
| n8n | Tak | Tak | Tak | Nie |
| NocoDB | Tak | Tak | Nie | Tak |
| MinIO | Tak | Tak | Nie | Tak |
| Qdrant | Tak | Tak | Nie | Nie |

## Uslugi i porty

| Usluga | Port | Local | VPS (pelny) | VPS n8n+workers | VPS nocodb |
|--------|------|-------|-------------|-----------------|------------|
| n8n | 5678 | localhost:5678 | n8n.DOMAIN | n8n.DOMAIN | - |
| nocodb | 8080 | localhost:8080 | nocodb.DOMAIN | - | nocodb.DOMAIN |
| minio console | 9001 | localhost:9001 | minio.DOMAIN | - | minio.DOMAIN |
| minio API | 9000 | localhost:9000 | api.minio.DOMAIN | - | api.minio.DOMAIN |
| qdrant | 6333 | localhost:6333 | qdrant.DOMAIN | - | - |
| pg_database | 5432 | - | - | - | - |
| redis | 6379 | - | - | - | - |
| caddy | 80, 443 | - | tak | tak | tak |

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
