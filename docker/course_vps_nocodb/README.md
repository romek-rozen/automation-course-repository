# NocoDB with MinIO - Docker Stack (VPS)

Stack produkcyjny NocoDB z MinIO na serwer VPS z automatycznym SSL.

## Architektura

```
                    [Internet]
                        |
                    [Caddy]
                   /        \
          nocodb.DOMAIN   minio.DOMAIN
              |                |
          [NocoDB]        [MinIO Console]
              |                |
              +-------+--------+
                      |
         +------------+------------+
         |            |            |
    [PostgreSQL]  [Redis]     [MinIO API]
```

**Komponenty:**
- **Caddy** - Reverse proxy z automatycznym SSL (Let's Encrypt)
- **NocoDB** - No-code database (UI + API)
- **PostgreSQL 16** - Baza danych NocoDB
- **Redis 8** - Cache dla NocoDB
- **MinIO** - S3-compatible storage dla plikow

## Wymagania

- Serwer VPS z Linux (Ubuntu 22.04+ / Debian 12+)
- Docker i Docker Compose
- Domena z rekordami DNS A wskazujacymi na serwer
- Otwarte porty: 80, 443
- Min. 2GB RAM (zalecane 4GB)

## Instalacja

```bash
# Krok 1: Pobierz repozytorium
curl -L -o repo.tar.gz https://github.com/romek-rozen/automation-course-repository/archive/main.tar.gz

# Krok 2: Rozpakuj archiwum
tar -xzf repo.tar.gz

# Krok 3: Utworz katalog docelowy
mkdir -p ~/docker

# Krok 4: Skopiuj zawartosc stacka
cp -r automation-course-repository-main/docker/course_vps_nocodb/. ~/docker/

# Krok 5: Usun pobrane pliki
rm -rf repo.tar.gz automation-course-repository-main

# Krok 6: Przejdz do katalogu i uruchom instalator
cd ~/docker
chmod +x init.sh setup.sh
./init.sh

# Krok 7: Uruchom stack
docker compose up -d
```

## Konfiguracja DNS

Dodaj rekordy A dla subdomen:

| Typ | Nazwa | Wartosc |
|-----|-------|---------|
| A | nocodb | IP_TWOJEGO_SERWERA |
| A | minio | IP_TWOJEGO_SERWERA |
| A | api.minio | IP_TWOJEGO_SERWERA (opcjonalnie) |

Propagacja DNS moze zajac do 24h (zwykle 5-30 min).

## Zmienne srodowiskowe

| Zmienna | Opis | Przyklad |
|---------|------|----------|
| DOMAIN | Domena bazowa | firma.pl |
| NOCODB_DOMAIN | Pelna domena NocoDB | nocodb.firma.pl |
| MINIO_DOMAIN | Pelna domena MinIO | minio.firma.pl |
| REDIS_PASSWORD | Haslo Redis | (generowane) |
| POSTGRES_PASSWORD | Haslo PostgreSQL superuser | (generowane) |
| POSTGRES_NOCODB_PASSWORD | Haslo PostgreSQL dla NocoDB | (generowane) |
| NC_JWT_SECRET | JWT Secret NocoDB | (generowane UUID) |
| MINIO_ROOT_PASSWORD | Haslo MinIO | (generowane) |

## PostgreSQL - struktura uzytkownikow

```
PostgreSQL
├── postgres (SUPERUSER) ← tylko do administracji i backupow
└── nocodb → nocodb_db   ← zwykly user z dostepem tylko do swojej bazy
```

Skrypt `init-data.sh` tworzy baze i uzytkownika przy pierwszym uruchomieniu PostgreSQL.

## Przydatne komendy

```bash
# Logi
docker compose logs -f
docker compose logs -f nocodb
docker compose logs -f minio

# Restart
docker compose restart
docker compose restart nocodb

# Status
docker compose ps

# Zatrzymanie
docker compose down

# Aktualizacja
docker compose pull && docker compose up -d

# Backup bazy (uzyj superusera postgres)
docker compose exec pg_database pg_dump -U postgres nocodb_db > backup.sql
```

## Struktura katalogow

```
course_vps_nocodb/
├── .env.example          # Szablon konfiguracji
├── docker-compose.yml    # Definicja uslug
├── init.sh               # Automatyczna konfiguracja
├── init-data.sh          # Skrypt PostgreSQL (tworzy baze i usera)
├── setup.sh              # Przygotowanie srodowiska
├── caddy/
│   └── Caddyfile         # Konfiguracja reverse proxy
├── README.md             # Ten plik
└── volumes/              # Dane aplikacji (po setup.sh)
    ├── nocodb/           # Dane NocoDB
    ├── db_data/          # Dane PostgreSQL
    ├── redis_data/       # Dane Redis
    ├── minio_data/       # Dane MinIO (pliki)
    ├── caddy_data/       # Certyfikaty SSL
    └── caddy_config/     # Konfiguracja Caddy
```

## Rozwiazywanie problemow

### Certyfikat SSL nie dziala
```bash
# Sprawdz DNS
nslookup nocodb.twoja-domena.pl

# Sprawdz logi Caddy
docker compose logs caddy
```

### NocoDB nie startuje
```bash
# Sprawdz logi
docker compose logs nocodb

# Sprawdz czy PostgreSQL dziala
docker compose exec pg_database pg_isready
```

### MinIO nie dziala
```bash
# Sprawdz logi
docker compose logs minio

# Sprawdz health
curl http://localhost:9000/minio/health/live
```

## Backup i przywracanie

### Pelny backup
```bash
# Zatrzymaj stack
docker compose down

# Backup
tar -czvf backup-nocodb-$(date +%Y%m%d).tar.gz volumes/

# Uruchom ponownie
docker compose up -d
```

### Przywracanie
```bash
docker compose down
tar -xzvf backup-nocodb-YYYYMMDD.tar.gz
docker compose up -d
```

## Porownanie z pelnym stackiem

| Element | vps_stack | vps_nocodb |
|---------|-----------|------------|
| Uslugi | 9 | 5 |
| Sekrety | 8 | 5 |
| Subdomeny | 5 | 2 (+1 opcjonalna api.minio) |
| RAM | ~6GB | ~2GB |
| n8n | Tak | Nie |
| NocoDB | Tak | Tak |
| MinIO | Tak | Tak |
| Qdrant | Tak | Nie |
