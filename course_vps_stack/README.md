# Instrukcja uruchomienia stacka Docker

## Instalacja

```bash
# Krok 1: Pobierz repozytorium
curl -L -o repo.tar.gz https://github.com/romek-rozen/automation-course-repository/archive/main.tar.gz

# Krok 2: Rozpakuj archiwum
tar -xzf repo.tar.gz

# Krok 3: Skopiuj stack do katalogu ~/docker
mv automation-course-repository-main/course_vps_stack ~/docker

# Krok 4: Usun niepotrzebne pliki
rm -rf repo.tar.gz automation-course-repository-main

# Krok 5: Przejdz do katalogu i uruchom instalator
cd ~/docker
chmod +x init.sh setup.sh
./init.sh

# Krok 6: Uruchom stack
docker compose up -d
```

> Po 1-2 minutach aplikacje beda dostepne pod Twoja domena z certyfikatem SSL.

---

## Wymagania

- Serwer VPS z systemem Linux (Ubuntu 22.04+ / Debian 12+)
- Docker i Docker Compose zainstalowane
- Domena wskazująca na serwer (rekordy DNS typu A)
- Otwarte porty: 80, 443

---

## Szybki start (automatyczna konfiguracja)

Skrypt `init.sh` automatycznie konfiguruje cale srodowisko:

```bash
chmod +x init.sh setup.sh
./init.sh
```

Skrypt:
- Sprawdzi wymagania systemowe (docker, openssl, uuidgen)
- Zapyta o domene bazowa i subdomeny
- Wygeneruje wszystkie hasla i klucze automatycznie
- Uruchomi `setup.sh`

Po zakonczeniu:
```bash
docker compose up -d
```

> Jesli wolisz reczna konfiguracje, przejdz do Kroku 1 ponizej.

---

## Krok 1: Konfiguracja DNS

Dodaj rekordy DNS dla swojej domeny (zamien `twoja-domena.pl` na swoja):

| Typ | Nazwa | Wartosc |
|-----|-------|---------|
| A | n8n | IP_TWOJEGO_SERWERA |
| A | nocodb | IP_TWOJEGO_SERWERA |
| A | minio | IP_TWOJEGO_SERWERA |
| A | api.minio | IP_TWOJEGO_SERWERA |
| A | qdrant | IP_TWOJEGO_SERWERA |

**Alternatywa: Wildcard DNS (zalecane)**

Zamiast dodawac kazda subdomena osobno, mozesz uzyc rekordu wildcard.

**Przyklad:** Masz domene `twoja-domena.pl` i chcesz uzyc subdomeny `auto` dla srodowiska:

| Typ | Nazwa | Pelna domena | Wartosc |
|-----|-------|--------------|---------|
| A | *.auto | *.auto.twoja-domena.pl | IP_TWOJEGO_SERWERA |
| A | auto | auto.twoja-domena.pl | IP_TWOJEGO_SERWERA |

Dzieki temu Twoje aplikacje beda dostepne pod:
- `n8n.auto.twoja-domena.pl`
- `nocodb.auto.twoja-domena.pl`
- `minio.auto.twoja-domena.pl`
- `qdrant.auto.twoja-domena.pl`

> **Uwaga:** Zapis nazwy zalezy od panelu DNS:
> - Niektore panele: wpisujesz tylko `*.auto` i `auto` (panel doda `.twoja-domena.pl`)
> - Inne panele: wpisujesz pelna nazwe `*.auto.twoja-domena.pl`

> Propagacja DNS moze zajac do 24h, ale zwykle trwa 5-30 minut.

---

## Krok 2: Konfiguracja zmiennych

> **Tip:** Zamiast recznej konfiguracji mozesz uzyc `./init.sh` - zobacz sekcje "Szybki start" wyzej.

1. Skopiuj plik `.env.example` do `.env`:

```bash
cp .env.example .env
```

2. Otworz plik `.env` w edytorze:

```bash
nano .env
```

3. Uzupelnij wszystkie wartosci:

### Domena
```bash
DOMAIN=twoja-domena.pl
```

### Hasla
Wygeneruj silne hasla dla kazdej uslugi. Mozesz uzyc:

```bash
# Generowanie losowego hasla (32 znaki)
openssl rand -base64 32

# Generowanie UUID
uuidgen
```

Przykladowe pola do uzupelnienia:
- `REDIS_PASSWORD` - haslo do Redis
- `POSTGRES_PASSWORD` - haslo do PostgreSQL
- `N8N_ENCRYPTION_KEY` - klucz szyfrowania n8n (openssl rand -base64 32)
- `NC_JWT_SECRET` - secret JWT dla NocoDB (uuidgen)
- `MINIO_ROOT_PASSWORD` - haslo do MinIO

4. Zapisz plik (Ctrl+O, Enter, Ctrl+X w nano)

---

## Krok 3: Uruchomienie setup.sh

```bash
chmod +x setup.sh
./setup.sh
```

Skrypt:
- Sprawdzi czy `.env` jest poprawnie skonfigurowany
- Utworzy strukture katalogow (`volumes/`)
- Utworzy siec Docker `caddy`
- Skopiuje Caddyfile

---

## Krok 4: Uruchomienie stacka

```bash
docker compose up -d
```

Sprawdz czy wszystkie kontenery dzialaja:

```bash
docker compose ps
```

Wszystkie uslugi powinny miec status `running` lub `healthy`.

---

## Krok 5: Dostep do aplikacji

Po uruchomieniu aplikacje beda dostepne pod adresami:

| Aplikacja | Adres |
|-----------|-------|
| n8n | https://n8n.twoja-domena.pl |
| NocoDB | https://nocodb.twoja-domena.pl |
| MinIO Console | https://minio.twoja-domena.pl |
| Qdrant API | https://qdrant.twoja-domena.pl |

> Certyfikaty SSL sa generowane automatycznie przez Caddy (Let's Encrypt).
> Pierwsze uruchomienie moze zajac 1-2 minuty na wygenerowanie certyfikatow.

---

## Przydatne komendy

### Logi
```bash
# Wszystkie logi
docker compose logs -f

# Logi konkretnej uslugi
docker compose logs -f n8n
docker compose logs -f nocodb
docker compose logs -f caddy
```

### Restart
```bash
# Restart wszystkiego
docker compose restart

# Restart konkretnej uslugi
docker compose restart n8n
```

### Zatrzymanie
```bash
# Zatrzymaj stack (dane zostaja)
docker compose down

# Zatrzymaj i usun woluminy (UWAGA: usuwa dane!)
docker compose down -v
```

### Aktualizacja obrazow
Aktualizacje wykonujesz recznie (zalecane dla wiekszej kontroli):

```bash
# Pobierz najnowsze wersje obrazow
docker compose pull

# Zrestartuj z nowymi wersjami
docker compose up -d

# Opcjonalnie: usun stare obrazy
docker image prune -a
```

---

## Struktura katalogow

Po uruchomieniu `setup.sh` powstanie struktura:

```
course_vps_stack/
├── .env                  # Twoja konfiguracja (nie commituj!)
├── .env.example          # Szablon konfiguracji
├── docker-compose.yml    # Definicja uslug
├── caddy/
│   └── Caddyfile         # Konfiguracja reverse proxy
├── init.sh               # Automatyczna konfiguracja (zalecane)
├── setup.sh              # Skrypt przygotowujacy srodowisko
└── volumes/              # Dane aplikacji
    ├── nocodb/           # Dane NocoDB
    ├── n8n/
    │   ├── data/         # Dane n8n
    │   └── local_files/  # Pliki lokalne n8n
    ├── db_data/          # Dane PostgreSQL
    ├── redis_data/       # Dane Redis
    ├── minio_data/       # Dane MinIO
    ├── qdrant_storage/   # Dane Qdrant
    ├── caddy_data/       # Certyfikaty SSL
    └── caddy_config/     # Konfiguracja Caddy
```

---

## Rozwiazywanie problemow

### Certyfikat SSL nie dziala
- Sprawdz czy DNS jest poprawnie skonfigurowany: `nslookup n8n.twoja-domena.pl`
- Sprawdz logi Caddy: `docker compose logs caddy`
- Upewnij sie ze porty 80 i 443 sa otwarte

### Kontener nie startuje
```bash
# Sprawdz logi
docker compose logs nazwa-uslugi

# Sprawdz healthcheck
docker inspect nazwa-uslugi | grep -A 10 Health
```

### Brak pamieci
```bash
# Sprawdz zuzycie
docker stats

# Zwolnij nieuzywane zasoby
docker system prune -a
```

### Reset danych (UWAGA!)
```bash
# Zatrzymaj stack
docker compose down

# Usun dane (nieodwracalne!)
rm -rf volumes/*

# Uruchom ponownie
./setup.sh
docker compose up -d
```

---

## Uslugi w stacku

| Usluga | Port wewn. | Opis |
|--------|-----------|------|
| caddy | 80, 443 | Reverse proxy z SSL |
| n8n | 5678 | Workflow automation (UI) |
| n8n-worker | 5678 | Przetwarza zadania z kolejki |
| n8n-webhook | 5678 | Odbiera webhooki produkcyjne |
| nocodb | 8080 | No-code database |
| pg_database | 5432 | PostgreSQL |
| redis | 6379 | Cache i kolejki |
| minio | 9000/9001 | S3 storage |
| qdrant | 6333/6334 | Vector database (REST/gRPC) |

---

## Backup

### Backup baz danych

**PostgreSQL:**
```bash
docker compose exec pg_database pg_dumpall -U postgres > backup_postgres.sql
```

### Backup plikow
```bash
tar -czvf backup_volumes.tar.gz volumes/
```

---

## Kontakt i wsparcie

W razie problemow:
1. Sprawdz logi: `docker compose logs -f`
2. Przeszukaj dokumentacje:
   - n8n: https://docs.n8n.io
   - NocoDB: https://docs.nocodb.com
   - Caddy: https://caddyserver.com/docs
