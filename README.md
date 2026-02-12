# Automation Course - Docker Stacks

Repozytorium zawiera gotowe konfiguracje Docker do kursu z automatyzacji.

## Struktura

```
.
└── docker/
    ├── course_local_stack/              # Wersja do nauki na lokalnej maszynie
    ├── course_vps_stack/                # Pelna wersja produkcyjna VPS (z workerami)
    ├── course_vps_stack_light/          # Light VPS - bez workerow, single n8n
    ├── course_vps_n8n_with_workers/     # Tylko n8n z workerami (queue mode)
    ├── course_vps_n8n_without_workers/  # Tylko n8n bez workerow (single instance)
    ├── course_vps_nocodb/               # Tylko NocoDB + MinIO
    └── course_vps_qdrant/               # Tylko Qdrant
```

## Ktora wersja?

| Wersja | Kiedy uzyc |
|--------|------------|
| **local_stack** | Nauka, testy, development na wlasnym komputerze |
| **vps_stack** | Pelne wdrozenie z workerami (duzy serwer, ~6GB RAM) |
| **vps_stack_light** | Pelne wdrozenie bez workerow (mniejszy serwer, ~4GB RAM) |
| **vps_n8n_with_workers** | Tylko n8n z workerami (queue mode) |
| **vps_n8n_without_workers** | Tylko n8n bez workerow (single instance) |
| **vps_nocodb** | Wdrozenie tylko NocoDB z MinIO (baza danych no-code) |
| **vps_qdrant** | Wdrozenie tylko Qdrant (vector database, RAG) |

## course_local_stack

Uproszczona wersja do nauki - bez SSL, bez domen, wszystko na localhost.

**Zawiera:** n8n (+ worker + webhook), NocoDB, MinIO, Qdrant, PostgreSQL, Redis

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

**Adresy po uruchomieniu:**
- n8n: http://localhost:5678
- NocoDB: http://localhost:8080
- MinIO: http://localhost:9001
- Qdrant: http://localhost:6333/dashboard

## course_vps_stack

Pelna wersja produkcyjna z Caddy (reverse proxy + automatyczne SSL).

**Zawiera:** Caddy, n8n (+ worker + webhook), NocoDB, MinIO, Qdrant, PostgreSQL, Redis

```bash
# Krok 1: Pobierz repozytorium
curl -L -o repo.tar.gz https://github.com/romek-rozen/automation-course-repository/archive/main.tar.gz

# Krok 2: Rozpakuj archiwum
tar -xzf repo.tar.gz

# Krok 3: Utworz katalog docelowy
mkdir -p ~/docker

# Krok 4: Skopiuj zawartosc stacka
cp -r automation-course-repository-main/docker/course_vps_stack/. ~/docker/

# Krok 5: Usun pobrane pliki
rm -rf repo.tar.gz automation-course-repository-main

# Krok 6: Przejdz do katalogu i uruchom instalator
cd ~/docker
chmod +x init.sh setup.sh
./init.sh

# Krok 7: Uruchom stack
docker compose up -d
```

**Wymagania:**
- VPS z Ubuntu 22.04+ / Debian 12+
- Domena z rekordami DNS wskazujacymi na serwer
- Docker i Docker Compose

## course_vps_stack_light

Light wersja produkcyjna - wszystkie uslugi ale bez workerow n8n (single instance).

**Zawiera:** Caddy, n8n (single), NocoDB, MinIO, Qdrant, PostgreSQL, Redis

```bash
# Krok 1: Pobierz repozytorium
curl -L -o repo.tar.gz https://github.com/romek-rozen/automation-course-repository/archive/main.tar.gz

# Krok 2: Rozpakuj archiwum
tar -xzf repo.tar.gz

# Krok 3: Utworz katalog docelowy
mkdir -p ~/docker

# Krok 4: Skopiuj zawartosc stacka
cp -r automation-course-repository-main/docker/course_vps_stack_light/. ~/docker/

# Krok 5: Usun pobrane pliki
rm -rf repo.tar.gz automation-course-repository-main

# Krok 6: Przejdz do katalogu i uruchom instalator
cd ~/docker
chmod +x init.sh setup.sh
./init.sh

# Krok 7: Uruchom stack
docker compose up -d
```

**Zalety vs pelny stack:**
- Mniejsze zuzycie zasobow (~4GB RAM vs ~6GB)
- Prostsza architektura (brak queue mode)
- Wszystkie uslugi dostepne (n8n, NocoDB, MinIO, Qdrant)

## course_vps_n8n_with_workers

Uproszczony stack produkcyjny - tylko n8n z architektura workerow.

**Zawiera:** Caddy, n8n (+ worker + webhook), PostgreSQL, Redis

```bash
# Krok 1: Pobierz repozytorium
curl -L -o repo.tar.gz https://github.com/romek-rozen/automation-course-repository/archive/main.tar.gz

# Krok 2: Rozpakuj archiwum
tar -xzf repo.tar.gz

# Krok 3: Utworz katalog docelowy
mkdir -p ~/docker

# Krok 4: Skopiuj zawartosc stacka
cp -r automation-course-repository-main/docker/course_vps_n8n_with_workers/. ~/docker/

# Krok 5: Usun pobrane pliki
rm -rf repo.tar.gz automation-course-repository-main

# Krok 6: Przejdz do katalogu i uruchom instalator
cd ~/docker
chmod +x init.sh setup.sh
./init.sh

# Krok 7: Uruchom stack
docker compose up -d
```

**Zalety vs pelny stack:**
- Mniejsze zuzycie zasobow (~2GB RAM vs ~6GB)
- Mniej sekretow do zarzadzania (4 vs 8)
- Prostsza konfiguracja DNS (1 subdomena vs 5)
- Szybsza instalacja

**Skalowanie workerow:**
```bash
docker compose up -d --scale n8n-worker=3
```

## course_vps_n8n_without_workers

Uproszczony stack produkcyjny - tylko n8n bez workerow (single instance).

**Zawiera:** Caddy, n8n (single), PostgreSQL, Redis

```bash
# Krok 1: Pobierz repozytorium
curl -L -o repo.tar.gz https://github.com/romek-rozen/automation-course-repository/archive/main.tar.gz

# Krok 2: Rozpakuj archiwum
tar -xzf repo.tar.gz

# Krok 3: Utworz katalog docelowy
mkdir -p ~/docker

# Krok 4: Skopiuj zawartosc stacka
cp -r automation-course-repository-main/docker/course_vps_n8n_without_workers/. ~/docker/

# Krok 5: Usun pobrane pliki
rm -rf repo.tar.gz automation-course-repository-main

# Krok 6: Przejdz do katalogu i uruchom instalator
cd ~/docker
chmod +x init.sh setup.sh
./init.sh

# Krok 7: Uruchom stack
docker compose up -d
```

**Zalety vs n8n z workerami:**
- Mniejsze zuzycie zasobow (~1.5GB RAM vs ~2GB)
- Prostsza architektura (brak queue mode)
- Mniej komponentow do monitorowania

## course_vps_nocodb

Uproszczony stack produkcyjny - tylko NocoDB z MinIO do przechowywania plikow.

**Zawiera:** Caddy, NocoDB, MinIO, PostgreSQL, Redis

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

**Zalety:**
- Lekki stack (~2GB RAM)
- NocoDB jako no-code baza danych
- MinIO do przechowywania zalacznikow
- 2 subdomeny (nocodb + minio)

## course_vps_qdrant

Minimalny stack produkcyjny - tylko Qdrant (vector database).

**Zawiera:** Caddy, Qdrant

```bash
# Krok 1: Pobierz repozytorium
curl -L -o repo.tar.gz https://github.com/romek-rozen/automation-course-repository/archive/main.tar.gz

# Krok 2: Rozpakuj archiwum
tar -xzf repo.tar.gz

# Krok 3: Utworz katalog docelowy
mkdir -p ~/docker

# Krok 4: Skopiuj zawartosc stacka
cp -r automation-course-repository-main/docker/course_vps_qdrant/. ~/docker/

# Krok 5: Usun pobrane pliki
rm -rf repo.tar.gz automation-course-repository-main

# Krok 6: Przejdz do katalogu i uruchom instalator
cd ~/docker
chmod +x init.sh setup.sh
./init.sh

# Krok 7: Uruchom stack
docker compose up -d
```

**Zalety:**
- Najlzejszy stack (tylko 2 uslugi)
- Qdrant autonomiczny - bez PostgreSQL/Redis
- Jeden sekret (API_KEY generowany automatycznie)
- Idealny do RAG, embeddings, wyszukiwania semantycznego

**Test API:**
```bash
curl -H "api-key: $QDRANT_API_KEY" https://qdrant.twoja-domena.pl/collections
```

## Licencja

MIT License - szczegoly w pliku [LICENSE](LICENSE)
