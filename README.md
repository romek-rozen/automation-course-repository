# Automation Course - Docker Stacks

Repozytorium zawiera gotowe konfiguracje Docker do kursu z automatyzacji.

## Struktura

```
.
├── course_local_stack/           # Wersja do nauki na lokalnej maszynie
├── course_vps_stack/             # Pelna wersja produkcyjna VPS
└── course_vps_n8n_with_workers/  # Uproszczony stack tylko n8n + workers
```

## Ktora wersja?

| Wersja | Kiedy uzyc |
|--------|------------|
| **local_stack** | Nauka, testy, development na wlasnym komputerze |
| **vps_stack** | Pelne wdrozenie z NocoDB, MinIO, Qdrant |
| **vps_n8n_with_workers** | Wdrozenie tylko n8n z workerami (lzejszy) |

## course_local_stack

Uproszczona wersja do nauki - bez SSL, bez domen, wszystko na localhost.

**Zawiera:** n8n (+ worker + webhook), NocoDB, MinIO, Qdrant, PostgreSQL, Redis

```bash
# Instalacja
curl -L https://github.com/romek-rozen/automation-course-repository/archive/main.tar.gz | tar -xz
mv automation-course-repository-main/course_local_stack ~/docker-local
rm -rf automation-course-repository-main
cd ~/docker-local
chmod +x init_local_stack.sh setup.sh
./init_local_stack.sh
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
# Instalacja na VPS
curl -L https://github.com/romek-rozen/automation-course-repository/archive/main.tar.gz | tar -xz
mv automation-course-repository-main/course_vps_stack ~/docker
rm -rf automation-course-repository-main
cd ~/docker
chmod +x init.sh setup.sh
./init.sh
docker compose up -d
```

**Wymagania:**
- VPS z Ubuntu 22.04+ / Debian 12+
- Domena z rekordami DNS wskazujacymi na serwer
- Docker i Docker Compose

## course_vps_n8n_with_workers

Uproszczony stack produkcyjny - tylko n8n z architektura workerow.

**Zawiera:** Caddy, n8n (+ worker + webhook), PostgreSQL, Redis

```bash
# Instalacja na VPS
git clone <repo-url>
cd course_vps_n8n_with_workers
chmod +x init.sh setup.sh
./init.sh
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

## Licencja

MIT License - szczegoly w pliku [LICENSE](LICENSE)
