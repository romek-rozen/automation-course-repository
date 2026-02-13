# CLAUDE.md - Docker Stacks

Szczegolowa dokumentacja techniczna dla Claude Code.

## Struktura katalogow

```
docker/
├── course_local_stack/           # Wersja lokalna (bez SSL, localhost)
│   ├── init_local_stack.sh       # Skrypt inicjalizacji
│   ├── init-data.sh              # Skrypt PostgreSQL (tworzy bazy i userow)
│   ├── setup.sh                  # Przygotowanie katalogow
│   ├── docker-compose.yml
│   └── .env.example
│
├── course_vps_stack/             # Pelna wersja VPS (Caddy + SSL)
│   ├── init.sh                   # Skrypt inicjalizacji z konfiguracja domen
│   ├── init-data.sh              # Skrypt PostgreSQL (tworzy bazy i userow)
│   ├── setup.sh                  # Przygotowanie katalogow i sieci
│   ├── docker-compose.yml
│   ├── .env.example
│   └── caddy/Caddyfile
│
├── course_vps_stack_light/       # Light VPS (bez workerow, single n8n)
│   ├── init.sh                   # Skrypt inicjalizacji z konfiguracja domen
│   ├── init-data.sh              # Skrypt PostgreSQL (tworzy bazy i userow)
│   ├── setup.sh                  # Przygotowanie katalogow i sieci
│   ├── docker-compose.yml        # 7 uslug (bez n8n-worker, n8n-webhook)
│   ├── .env.example
│   └── caddy/Caddyfile
│
├── course_vps_n8n_with_workers/  # VPS n8n z workerami (queue mode)
│   ├── init.sh                   # Skrypt inicjalizacji
│   ├── init-data.sh              # Skrypt PostgreSQL (tworzy baze i usera)
│   ├── setup.sh                  # Przygotowanie katalogow i sieci
│   ├── docker-compose.yml        # 6 uslug (bez NocoDB, MinIO, Qdrant)
│   ├── .env.example              # 5 sekretow
│   └── caddy/Caddyfile           # Tylko routing n8n
│
├── course_vps_n8n_without_workers/ # VPS n8n bez workerow (single instance)
│   ├── init.sh                   # Skrypt inicjalizacji
│   ├── init-data.sh              # Skrypt PostgreSQL (tworzy baze i usera)
│   ├── setup.sh                  # Przygotowanie katalogow i sieci
│   ├── docker-compose.yml        # 4 uslugi (n8n, PostgreSQL, Redis, Caddy)
│   ├── .env.example              # 5 sekretow
│   └── caddy/Caddyfile           # Tylko routing n8n
│
├── course_vps_nocodb/            # Uproszczony VPS (tylko NocoDB + MinIO)
│   ├── init.sh                   # Skrypt inicjalizacji
│   ├── init-data.sh              # Skrypt PostgreSQL (tworzy baze i usera)
│   ├── setup.sh                  # Przygotowanie katalogow i sieci
│   ├── docker-compose.yml        # 5 uslug (bez n8n, Qdrant)
│   ├── .env.example              # 5 sekretow
│   └── caddy/Caddyfile           # Routing nocodb + minio
│
├── course_vps_qdrant/            # Uproszczony VPS (tylko Qdrant)
│   ├── init.sh                   # Skrypt inicjalizacji
│   ├── setup.sh                  # Przygotowanie katalogow i sieci
│   ├── docker-compose.yml        # 2 uslugi (Caddy + Qdrant)
│   ├── .env.example              # 1 sekret (QDRANT_API_KEY)
│   └── caddy/Caddyfile           # Routing qdrant.DOMAIN
│
└── course_vps_elestio_light/     # Light stack dla Elestio CI/CD
    ├── docker-compose.yml        # 6 uslug (bez Caddy/Qdrant, porty na 172.17.0.1, pg-init)
    └── .env.example              # Zmienne dla Elestio CI/CD
```

## Architektura stackow

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

### Light stack (course_vps_stack_light)

```
[Caddy]
    ├── n8n (single instance - UI + API + webhooks)
    ├── NocoDB (no-code database)
    ├── MinIO Console (S3 storage)
    └── Qdrant (vector database)

PostgreSQL ← n8n, NocoDB
Redis ← NocoDB (cache /15), n8n (workflow)
MinIO ← NocoDB (pliki)
Qdrant ← n8n (embeddings, RAG)
```

Jak pelny stack, ale bez n8n-worker i n8n-webhook (brak queue mode).

### Stack n8n (course_vps_n8n_with_workers)

```
[Caddy]
    └── n8n (UI + API)
        ├── n8n-worker (przetwarza kolejke)
        └── n8n-webhook (odbiera webhooki)

PostgreSQL ← n8n
Redis ← n8n (kolejki Bull /14)
```

n8n uzywa wzorca YAML anchor (`x-n8n-shared`) dla wspoldzielonej konfiguracji.

### Stack n8n bez workerow (course_vps_n8n_without_workers)

```
[Caddy]
    └── n8n (single instance - UI + API + webhooks)

PostgreSQL ← n8n
Redis ← n8n (workflow)
```

Jak n8n_with_workers, ale bez queue mode, workera i webhooka.

### Stack NocoDB (course_vps_nocodb)

```
[Caddy]
    ├── NocoDB (no-code database)
    └── MinIO Console (S3 storage)

PostgreSQL ← NocoDB
Redis ← NocoDB (cache /15)
MinIO ← NocoDB (pliki/attachmenty)
```

### Stack Qdrant (course_vps_qdrant)

```
[Caddy]
    └── Qdrant (vector database)

Qdrant jest autonomiczny - nie wymaga PostgreSQL ani Redis.
Autentykacja przez API_KEY + JWT RBAC.
```

### Elestio Light stack (course_vps_elestio_light)

```
[Elestio Nginx] (external)
    ├── n8n (172.17.0.1:5678)
    ├── NocoDB (172.17.0.1:8080)
    └── MinIO Console (172.17.0.1:9001)

PostgreSQL ← n8n, NocoDB
Redis ← NocoDB (cache /15), n8n (workflow)
MinIO ← NocoDB (pliki)
```

Jak light stack, ale bez Caddy - Elestio zapewnia reverse proxy + SSL.
Porty bindowane na 172.17.0.1 (Docker bridge IP).

## Komendy

```bash
# === LOCAL STACK ===
cd docker/course_local_stack
./init_local_stack.sh        # Inicjalizacja (opcjonalne silne hasla)
docker compose up -d

# === VPS STACK (pelny) ===
cd docker/course_vps_stack
./init.sh                    # Inicjalizacja (konfiguracja domen + generowanie hasel)
docker compose up -d

# === VPS STACK LIGHT (bez workerow) ===
cd docker/course_vps_stack_light
./init.sh                    # Inicjalizacja (4 domeny + 9 sekretow)
docker compose up -d

# === VPS N8N WITH WORKERS ===
cd docker/course_vps_n8n_with_workers
./init.sh                    # Inicjalizacja (1 domena + 5 sekretow)
docker compose up -d
docker compose up -d --scale n8n-worker=3  # Skalowanie workerow

# === VPS N8N WITHOUT WORKERS ===
cd docker/course_vps_n8n_without_workers
./init.sh                    # Inicjalizacja (1 domena + 5 sekretow)
docker compose up -d

# === VPS NOCODB ===
cd docker/course_vps_nocodb
./init.sh                    # Inicjalizacja (2 domeny + 5 sekretow)
docker compose up -d

# === VPS QDRANT ===
cd docker/course_vps_qdrant
./init.sh                    # Inicjalizacja (1 domena + 1 sekret)
docker compose up -d

# === ELESTIO LIGHT ===
cd docker/course_vps_elestio_light
# Zmienne wstrzykiwane przez Elestio CI/CD
docker compose up -d

# === Wspolne ===
docker compose logs -f [nazwa-uslugi]
docker compose pull && docker compose up -d
docker compose exec pg_database pg_dump -U postgres n8n_db > backup.sql
```

## Roznice miedzy stackami

| Cecha | Local | VPS (pelny) | VPS light | VPS n8n+workers | VPS n8n (no workers) | VPS nocodb | VPS qdrant | Elestio light |
|-------|-------|-------------|-----------|-----------------|---------------------|------------|------------|---------------|
| Reverse proxy | Brak | Caddy | Caddy | Caddy | Caddy | Caddy | Caddy | Elestio Nginx |
| SSL | Brak | Let's Encrypt | Let's Encrypt | Let's Encrypt | Let's Encrypt | Let's Encrypt | Let's Encrypt | Elestio |
| Hasla | Domyslne | 8 sekretow | 8 sekretow | 5 sekretow | 5 sekretow | 5 sekretow | 1 sekret | 8 sekretow |
| Domeny | localhost | 5 subdomen | 4 subdomeny | 1 subdomena | 1 subdomena | 2 subdomeny | 1 subdomena | Elestio |
| Uslugi | 9 | 9 | 7 | 6 | 4 | 5 | 2 | 5+pg-init |
| RAM | ~4GB | ~6GB | ~4GB | ~2GB | ~1.5GB | ~2GB | ~2.5GB | ~4GB |
| Queue mode | Tak | Tak | Nie | Tak | Nie | - | - | Nie |
| n8n | Tak | Tak | Tak | Tak | Tak | Nie | Nie | Tak |
| NocoDB | Tak | Tak | Tak | Nie | Nie | Tak | Nie | Tak |
| MinIO | Tak | Tak | Tak | Nie | Nie | Tak | Nie | Tak |
| Qdrant | Tak | Tak | Tak | Nie | Nie | Nie | Tak | Nie |

## Uslugi i porty

| Usluga | Port | Local | VPS (pelny) | VPS light | VPS n8n+workers | VPS n8n (no workers) | VPS nocodb | VPS qdrant | Elestio light |
|--------|------|-------|-------------|-----------|-----------------|---------------------|------------|------------|---------------|
| n8n | 5678 | localhost:5678 | n8n.DOMAIN | n8n.DOMAIN | n8n.DOMAIN | n8n.DOMAIN | - | - | 172.17.0.1:5678 |
| nocodb | 8080 | localhost:8080 | nocodb.DOMAIN | nocodb.DOMAIN | - | - | nocodb.DOMAIN | - | 172.17.0.1:8080 |
| minio console | 9001 | localhost:9001 | minio.DOMAIN | minio.DOMAIN | - | - | minio.DOMAIN | - | 172.17.0.1:9001 |
| minio API | 9000 | localhost:9000 | api.minio.DOMAIN | api.minio.DOMAIN | - | - | api.minio.DOMAIN | - | 172.17.0.1:9000 |
| qdrant | 6333 | localhost:6333 | qdrant.DOMAIN | qdrant.DOMAIN | - | - | - | qdrant.DOMAIN | - |
| pg_database | 5432 | - | - | - | - | - | - | - | - |
| redis | 6379 | - | - | - | - | - | - | - | - |
| caddy | 80, 443 | - | tak | tak | tak | tak | tak | tak | - |

## Konfiguracja

Pliki `.env.example` zawieraja wszystkie zmienne:
- **Local**: domyslne wartosci, opcjonalne generowanie przez `openssl rand -base64 32`
- **VPS**: placeholdery, wymagane generowanie przez `init.sh`

Redis uzywa osobnych baz: `/15` dla NocoDB, `/14` dla n8n queue.

## PostgreSQL - struktura uzytkownikow

```
PostgreSQL
├── postgres (SUPERUSER) ← tylko do administracji i backupow
├── nocodb → nocodb_db   ← zwykly user z dostepem tylko do swojej bazy
└── n8n → n8n_db         ← zwykly user z dostepem tylko do swojej bazy
```

Skrypt `init-data.sh` tworzy bazy i uzytkownikow przy pierwszym uruchomieniu PostgreSQL.
