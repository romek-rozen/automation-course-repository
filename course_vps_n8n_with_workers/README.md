# n8n with Workers - Docker Stack (VPS)

Stack produkcyjny n8n z architektura workerow na serwer VPS z automatycznym SSL.

## Architektura

```
                    [Internet]
                        |
                    [Caddy]
                   /   |    \
          /webhook/*   |     (pozostale)
              |        |           |
        [n8n-webhook]  |       [n8n main]
              |        |           |
              +--------+-----------+
                       |
            +----------+----------+
            |                     |
       [PostgreSQL]           [Redis]
            |                     |
            +----------+----------+
                       |
                 [n8n-worker]
```

**Komponenty:**
- **Caddy** - Reverse proxy z automatycznym SSL (Let's Encrypt)
- **n8n** - Glowna instancja (UI + API)
- **n8n-worker** - Przetwarza zadania z kolejki Redis
- **n8n-webhook** - Odbiera produkcyjne webhooki
- **PostgreSQL 16** - Baza danych n8n
- **Redis 8** - Kolejki Bull dla workerow

## Wymagania

- Serwer VPS z Linux (Ubuntu 22.04+ / Debian 12+)
- Docker i Docker Compose
- Domena z rekord DNS A wskazujacym na serwer
- Otwarte porty: 80, 443
- Min. 2GB RAM (zalecane 4GB+)

## Instalacja

```bash
# Krok 1: Pobierz repozytorium
curl -L -o repo.tar.gz https://github.com/romek-rozen/automation-course-repository/archive/main.tar.gz

# Krok 2: Rozpakuj archiwum
tar -xzf repo.tar.gz

# Krok 3: Utworz katalog docelowy
mkdir -p ~/docker

# Krok 4: Skopiuj zawartosc stacka
cp -r automation-course-repository-main/course_vps_n8n_with_workers/. ~/docker/

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

Dodaj rekord A dla subdomeny n8n:

| Typ | Nazwa | Wartosc |
|-----|-------|---------|
| A | n8n | IP_TWOJEGO_SERWERA |

Propagacja DNS moze zajac do 24h (zwykle 5-30 min).

## Zmienne srodowiskowe

| Zmienna | Opis | Przyklad |
|---------|------|----------|
| DOMAIN | Domena bazowa | firma.pl |
| N8N_DOMAIN | Pelna domena n8n | n8n.firma.pl |
| REDIS_PASSWORD | Haslo Redis | (generowane) |
| POSTGRES_PASSWORD | Haslo PostgreSQL superuser | (generowane) |
| POSTGRES_N8N_PASSWORD | Haslo PostgreSQL dla n8n | (generowane) |
| N8N_ENCRYPTION_KEY | Klucz szyfrowania n8n | (generowane) |
| N8N_GENERIC_TIMEZONE | Strefa czasowa | Europe/Warsaw |
| N8N_SMTP_* | Konfiguracja email | (opcjonalne) |

## PostgreSQL - struktura uzytkownikow

```
PostgreSQL
├── postgres (SUPERUSER) ← tylko do administracji i backupow
└── n8n → n8n_db         ← zwykly user z dostepem tylko do swojej bazy
```

Skrypt `init-data.sh` tworzy baze i uzytkownika przy pierwszym uruchomieniu PostgreSQL.

## Skalowanie workerow

Aby dodac wiecej workerow:

```bash
# Skaluj do 3 workerow
docker compose up -d --scale n8n-worker=3

# Sprawdz status
docker compose ps
```

## Przydatne komendy

```bash
# Logi
docker compose logs -f
docker compose logs -f n8n
docker compose logs -f n8n-worker

# Restart
docker compose restart
docker compose restart n8n

# Status
docker compose ps

# Zatrzymanie
docker compose down

# Aktualizacja
docker compose pull && docker compose up -d

# Backup bazy (uzyj superusera postgres)
docker compose exec pg_database pg_dump -U postgres n8n_db > backup.sql
```

## Struktura katalogow

```
course_vps_n8n_with_workers/
├── .env.example          # Szablon konfiguracji
├── docker-compose.yml    # Definicja uslug
├── init.sh               # Automatyczna konfiguracja
├── init-data.sh          # Skrypt PostgreSQL (tworzy baze i usera)
├── setup.sh              # Przygotowanie srodowiska
├── caddy/
│   └── Caddyfile         # Konfiguracja reverse proxy
├── README.md             # Ten plik
└── volumes/              # Dane aplikacji (po setup.sh)
    ├── n8n/
    │   ├── data/         # Dane n8n
    │   └── local_files/  # Pliki lokalne
    ├── db_data/          # Dane PostgreSQL
    ├── redis_data/       # Dane Redis
    ├── caddy_data/       # Certyfikaty SSL
    └── caddy_config/     # Konfiguracja Caddy
```

## Rozwiazywanie problemow

### Certyfikat SSL nie dziala
```bash
# Sprawdz DNS
nslookup n8n.twoja-domena.pl

# Sprawdz logi Caddy
docker compose logs caddy
```

### Worker nie przetwarza zadan
```bash
# Sprawdz logi workera
docker compose logs n8n-worker

# Sprawdz Redis
docker compose exec redis redis-cli -a $REDIS_PASSWORD INFO
```

### Brak pamieci
```bash
# Sprawdz zuzycie
docker stats

# Wyczysc nieuzywane obrazy
docker system prune -a
```

## Backup i przywracanie

### Pelny backup
```bash
# Zatrzymaj stack
docker compose down

# Backup
tar -czvf backup-n8n-$(date +%Y%m%d).tar.gz volumes/

# Uruchom ponownie
docker compose up -d
```

### Przywracanie
```bash
docker compose down
tar -xzvf backup-n8n-YYYYMMDD.tar.gz
docker compose up -d
```

## Porownanie z pelnym stackiem

| Element | vps_stack | vps_n8n_with_workers |
|---------|-----------|----------------------|
| Uslugi | 9 | 6 |
| Sekrety | 8 | 5 |
| Subdomeny | 5 | 1 |
| RAM | ~6GB | ~2GB |
| NocoDB | Tak | Nie |
| MinIO | Tak | Nie |
| Qdrant | Tak | Nie |

## Licencja

MIT License
