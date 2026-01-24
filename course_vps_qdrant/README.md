# Qdrant Vector Database - Docker Stack (VPS)

Stack produkcyjny Qdrant na serwer VPS z automatycznym SSL.

## Architektura

```
                    [Internet]
                        |
                    [Caddy]
                        |
              qdrant.DOMAIN (HTTPS)
                        |
                    [Qdrant]
```

**Komponenty:**
- **Caddy** - Reverse proxy z automatycznym SSL (Let's Encrypt)
- **Qdrant** - Vector database z API key + JWT RBAC

## Wymagania

- Serwer VPS z Linux (Ubuntu 22.04+ / Debian 12+)
- Docker i Docker Compose
- Domena z rekordem DNS A wskazujacym na serwer
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
cp -r automation-course-repository-main/course_vps_qdrant/. ~/docker/

# Krok 5: Usun pobrane pliki
rm -rf repo.tar.gz automation-course-repository-main

# Krok 6: Przejdz do katalogu i uruchom instalator
cd ~/docker
chmod +x init.sh setup.sh
./init.sh

# Krok 7: Uruchom stack
docker compose up -d
```

> Po 1-2 minutach Qdrant bedzie dostepny pod Twoja domena z certyfikatem SSL.

---

## Konfiguracja DNS

Dodaj rekord DNS dla swojej domeny:

| Typ | Nazwa | Wartosc |
|-----|-------|---------|
| A | qdrant | IP_TWOJEGO_SERWERA |

> Propagacja DNS moze zajac do 24h, ale zwykle trwa 5-30 minut.

---

## Dostep do API

Po uruchomieniu Qdrant bedzie dostepny pod adresem:

| Usluga | Adres |
|--------|-------|
| Qdrant REST API | https://qdrant.twoja-domena.pl |

### Autentykacja

Qdrant wymaga klucza API w naglowku `api-key`:

```bash
# Sprawdz kolekcje
curl -H "api-key: TWOJ_QDRANT_API_KEY" https://qdrant.twoja-domena.pl/collections

# Sprawdz status
curl -H "api-key: TWOJ_QDRANT_API_KEY" https://qdrant.twoja-domena.pl/
```

---

## Przydatne komendy

### Logi
```bash
# Wszystkie logi
docker compose logs -f

# Logi konkretnej uslugi
docker compose logs -f qdrant
docker compose logs -f caddy
```

### Restart
```bash
# Restart wszystkiego
docker compose restart

# Restart konkretnej uslugi
docker compose restart qdrant
```

### Zatrzymanie
```bash
# Zatrzymaj stack (dane zostaja)
docker compose down

# Zatrzymaj i usun woluminy (UWAGA: usuwa dane!)
docker compose down -v
```

### Aktualizacja
```bash
# Pobierz najnowsze wersje obrazow
docker compose pull

# Zrestartuj z nowymi wersjami
docker compose up -d
```

---

## Struktura katalogow

Po uruchomieniu `setup.sh` powstanie struktura:

```
course_vps_qdrant/
├── .env                  # Twoja konfiguracja (nie commituj!)
├── .env.example          # Szablon konfiguracji
├── docker-compose.yml    # Definicja uslug
├── caddy/
│   └── Caddyfile         # Konfiguracja reverse proxy
├── init.sh               # Automatyczna konfiguracja (zalecane)
├── setup.sh              # Skrypt przygotowujacy srodowisko
└── volumes/              # Dane aplikacji
    ├── qdrant_storage/   # Dane Qdrant (kolekcje, wektory)
    ├── caddy_data/       # Certyfikaty SSL
    └── caddy_config/     # Konfiguracja Caddy
```

---

## Uslugi w stacku

| Usluga | Port wewn. | Opis |
|--------|-----------|------|
| caddy | 80, 443 | Reverse proxy z SSL |
| qdrant | 6333, 6334 | Vector database (REST/gRPC) |

---

## Rozwiazywanie problemow

### Certyfikat SSL nie dziala
- Sprawdz czy DNS jest poprawnie skonfigurowany: `nslookup qdrant.twoja-domena.pl`
- Sprawdz logi Caddy: `docker compose logs caddy`
- Upewnij sie ze porty 80 i 443 sa otwarte

### Qdrant nie odpowiada
```bash
# Sprawdz logi
docker compose logs qdrant

# Sprawdz healthcheck
docker inspect qdrant | grep -A 10 Health
```

### Blad autentykacji (401)
- Upewnij sie ze uzywasz poprawnego klucza API z pliku `.env` lub `secrets.txt`
- Sprawdz czy naglowek to `api-key` (nie `Authorization`)

### Brak pamieci
```bash
# Sprawdz zuzycie
docker stats

# Zwolnij nieuzywane zasoby
docker system prune -a
```

---

## Kontakt i wsparcie

W razie problemow:
1. Sprawdz logi: `docker compose logs -f`
2. Przeszukaj dokumentacje: https://qdrant.tech/documentation/
