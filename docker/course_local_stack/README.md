# Docker Stack - Wersja Lokalna

Wersja stacka Docker przeznaczona do nauki i testow na lokalnej maszynie.
Zawiera pelny tryb kolejkowy (n8n + worker + webhook) jak wersja VPS.

## Instalacja

```bash
# Krok 1: Pobierz repozytorium
curl -L -o repo.tar.gz https://github.com/romek-rozen/automation-course-repository/archive/main.tar.gz

# Krok 2: Rozpakuj archiwum
tar -xzf repo.tar.gz

# Krok 3: Utworz katalog docelowy
mkdir -p ~/docker-local

# Krok 4: Skopiuj zawartosc stacka
cp -r automation-course-repository-main/docker/course_local_stack/. ~/docker-local/

# Krok 5: Usun pobrane pliki
rm -rf repo.tar.gz automation-course-repository-main

# Krok 6: Przejdz do katalogu i uruchom instalator
cd ~/docker-local
chmod +x init_local_stack.sh setup.sh
./init_local_stack.sh

# Krok 7: Uruchom stack
docker compose up -d
```

> Po ~30-60 sekundach aplikacje beda dostepne pod adresami localhost.

---

## Instalacja (Windows)

### Wymagania
- Docker Desktop dla Windows (z WSL 2)
- PowerShell

### Krok 1: Pobierz repozytorium

**Opcja A - przez Git:**
```powershell
git clone https://github.com/romek-rozen/automation-course-repository.git
cd automation-course-repository\docker\course_local_stack
```

**Opcja B - bez Git:**
1. Pobierz ZIP: https://github.com/romek-rozen/automation-course-repository/archive/main.zip
2. Rozpakuj archiwum
3. Otwórz PowerShell w katalogu `automation-course-repository-main\docker\course_local_stack`

### Krok 2: Przygotuj srodowisko

```powershell
# Skopiuj plik konfiguracyjny
Copy-Item .env.example .env

# Utworz katalogi dla danych
mkdir -Force volumes\nocodb
mkdir -Force volumes\n8n\data
mkdir -Force volumes\n8n\local_files
mkdir -Force volumes\redis_data
mkdir -Force volumes\minio_data
mkdir -Force volumes\qdrant_storage
mkdir -Force volumes\db_data
```

### Krok 3: Uruchom stack

```powershell
docker compose up -d
```

> Po ~30-60 sekundach aplikacje beda dostepne pod adresami localhost.
> Domyslne hasla z pliku .env sa wystarczajace do nauki. Mozesz je zmienic edytujac plik .env przed uruchomieniem stacka.

---

## Szybki start (jesli masz juz pliki)

```bash
# 1. Przygotuj srodowisko
chmod +x init_local_stack.sh setup.sh
./init_local_stack.sh

# 2. Uruchom stack
docker compose up -d

# 3. Poczekaj ~30-60 sekund i sprawdz status
docker compose ps
```

## Wymagania

- Docker i Docker Compose
- ~4GB RAM wolnego
- ~5GB miejsca na dysku

## Adresy aplikacji

| Aplikacja | Adres | Logowanie |
|-----------|-------|-----------|
| n8n | http://localhost:5678 | Utworz konto przy pierwszym logowaniu |
| NocoDB | http://localhost:8080 | Utworz konto przy pierwszym logowaniu |
| MinIO Console | http://localhost:9001 | minioadmin / (haslo z .env) |
| Qdrant Dashboard | http://localhost:6333/dashboard | Brak autoryzacji |

## Porty

| Usluga | Port | Opis |
|--------|------|------|
| n8n | 5678 | Workflow automation |
| NocoDB | 8080 | No-code database |
| MinIO API | 9000 | S3-compatible API |
| MinIO Console | 9001 | Panel administracyjny |
| Qdrant REST | 6333 | Vector database API |
| Qdrant gRPC | 6334 | Vector database gRPC |
| PostgreSQL | 5432 | Baza danych |
| Redis | 6379 | Cache |

## Przydatne komendy

```bash
# Uruchomienie
docker compose up -d

# Zatrzymanie
docker compose down

# Zatrzymanie z usunieciem danych
docker compose down -v

# Logi wszystkich uslug
docker compose logs -f

# Logi konkretnej uslugi
docker compose logs -f n8n

# Status uslug
docker compose ps

# Restart pojedynczej uslugi
docker compose restart n8n

# Aktualizacja obrazow
docker compose pull && docker compose up -d

# Backup PostgreSQL
docker compose exec pg_database pg_dumpall -U postgres > backup.sql
```

## Struktura katalogow

```
course_local_stack/
├── .env                  # Twoja konfiguracja (po init)
├── .env.example          # Szablon konfiguracji
├── docker-compose.yml    # Definicja uslug
├── init_local_stack.sh   # Skrypt inicjalizacji (uruchom pierwszy)
├── init-data.sh          # Skrypt PostgreSQL (tworzy bazy i userow)
├── setup.sh              # Skrypt przygotowujacy katalogi
├── README.md             # Ta dokumentacja
└── volumes/              # Dane aplikacji (po init)
    ├── nocodb/
    ├── n8n/
    │   ├── data/
    │   └── local_files/
    ├── db_data/
    ├── redis_data/
    ├── minio_data/
    └── qdrant_storage/
```

## Roznice wobec wersji VPS

| Cecha | VPS | Lokalna |
|-------|-----|---------|
| Reverse proxy | Caddy (SSL) | Brak |
| Protokol | HTTPS | HTTP |
| n8n instances | 3 (main + worker + webhook) | 3 (main + worker + webhook) |
| n8n execution mode | Queue | Queue |
| Domena | Wymagana | localhost |
| SMTP | Konfigurowalny | Brak |
| API Keys | Wymagane | Brak |
| Limity zasobow | Tak | Brak |

## Rozwiazywanie problemow

### Usluga nie startuje
```bash
docker compose logs nazwa_uslugi
```

### Port juz zajety
Zmien port w docker-compose.yml, np.:
```yaml
ports:
  - "5679:5678"  # n8n na porcie 5679
```

### Brak miejsca na dysku
```bash
docker system prune -a
```

### Reset do stanu poczatkowego
```bash
docker compose down -v
rm -rf volumes/ .env
./init_local_stack.sh
docker compose up -d
```
