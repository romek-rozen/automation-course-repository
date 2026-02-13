# Elestio Light Stack

Light stack dla Elestio CI/CD - bez Caddy, bez workerow n8n.

**Uslugi:** n8n, NocoDB, MinIO, PostgreSQL, Redis

## Konfiguracja w panelu Elestio

### 1. Docker compose

Wklej zawartosc pliku `docker-compose.yml` do pola "docker-compose.yml".

### 2. Environment variables

Wklej do pola `.env` (zmien wartosci hasel!):

```env
SOFTWARE_VERSION_TAG=latest
DOMAIN=[CI_CD_DOMAIN]

# Redis
REDIS_PASSWORD=ZMIEN_NA_SILNE_HASLO

# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=ZMIEN_NA_SILNE_HASLO
POSTGRES_NOCODB_DB=nocodb_db
POSTGRES_NOCODB_USER=nocodb
POSTGRES_NOCODB_PASSWORD=ZMIEN_NA_SILNE_HASLO
POSTGRES_N8N_DB=n8n_db
POSTGRES_N8N_USER=n8n
POSTGRES_N8N_PASSWORD=ZMIEN_NA_SILNE_HASLO

# n8n
N8N_ENCRYPTION_KEY=ZMIEN_NA_SILNE_HASLO
N8N_USER_MANAGEMENT_JWT_SECRET=ZMIEN_NA_SILNE_HASLO
N8N_GENERIC_TIMEZONE=Europe/Warsaw
N8N_SMTP_HOST=172.17.0.1
N8N_SMTP_PORT=25
N8N_SMTP_USER=
N8N_SMTP_PASS=
N8N_SMTP_SENDER=

# NocoDB
NC_JWT_SECRET=ZMIEN_NA_UUID

# MinIO
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=ZMIEN_NA_SILNE_HASLO
```

> `[CI_CD_DOMAIN]` - Elestio automatycznie podmieni na Twoja domene.
> Hasla wygeneruj: `openssl rand -hex 32`
> UUID wygeneruj: `uuidgen` lub https://www.uuidgenerator.net/

### 3. Reverse proxy configuration

Domyslnie Elestio tworzy 1 regule. Musisz skonfigurowac **3 reguly** (kliknij "+ Add Another"):

| # | Listen (Protocol) | Listen (Port) | Target (Protocol) | Target (IP) | Target (Port) | Target (Path) | Opis |
|---|-------------------|---------------|--------------------|--------------|----|---|------|
| 1 | HTTPS | 443 | HTTP | 172.17.0.1 | 5678 | / | n8n |
| 2 | HTTPS | 24580 | HTTP | 172.17.0.1 | 8080 | / | NocoDB |
| 3 | HTTPS | 24581 | HTTP | 172.17.0.1 | 9001 | / | MinIO Console |

> **Uwaga:** Porty 24580 i 24581 to przykladowe porty publiczne.
> Mozesz wybrac inne wolne porty (np. 8443, 9443).
> Po deploy Elestio poda Ci adresy dostepu.

### 4. Pipeline Name

Wpisz nazwe np. `automation-light-stack`.

## Po deployu

Elestio poda adresy:
- **n8n:** `https://twoja-domena.elestio.app:443`
- **NocoDB:** `https://twoja-domena.elestio.app:24580`
- **MinIO Console:** `https://twoja-domena.elestio.app:24581`

## Pliki

| Plik | Opis |
|------|------|
| `docker-compose.yml` | Konfiguracja Docker (wklej do Elestio) |
| `.env.example` | Szablon zmiennych srodowiskowych |
| `README.md` | Ta instrukcja |
