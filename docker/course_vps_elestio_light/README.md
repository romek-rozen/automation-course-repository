# Elestio Light Stack

Light stack dla Elestio CI/CD - bez Caddy, bez workerow n8n.

**Uslugi:** n8n, NocoDB, MinIO, PostgreSQL, Redis

## Konfiguracja w panelu Elestio

### 1. Docker compose

Wklej zawartosc pliku `docker-compose.yml` do pola "docker-compose.yml".

### 2. Environment variables

Wklej zawartosc pliku `.env.example` do pola `.env`.

**Wazne:** Przed wklejeniem wygeneruj wlasne hasla dla kazdej zmiennej oznaczonej komentarzem `# Generuj:`:

```bash
# Hasla (hex 32 znaki):
openssl rand -hex 32

# UUID (dla NC_JWT_SECRET):
uuidgen
```

Zmienne wymagajace wlasnych hasel:
- `REDIS_PASSWORD`
- `POSTGRES_PASSWORD`
- `POSTGRES_NOCODB_PASSWORD`
- `POSTGRES_N8N_PASSWORD`
- `N8N_ENCRYPTION_KEY`
- `N8N_USER_MANAGEMENT_JWT_SECRET`
- `NC_JWT_SECRET` (UUID)
- `MINIO_ROOT_PASSWORD`

> `[CI_CD_DOMAIN]` - Elestio automatycznie podmieni na Twoja domene.

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

## Wlasne subdomeny (opcjonalne)

Zamiast portow mozesz podpiac wlasne subdomeny. W panelu Elestio:

1. Wejdz w **Settings** → **Custom Domains**
2. Dodaj subdomeny i przypisz je do odpowiednich portow:

| Subdomena | Port docelowy | Usluga |
|-----------|---------------|--------|
| `n8n.twoja-domena.pl` | 443 | n8n |
| `nocodb.twoja-domena.pl` | 24580 | NocoDB |
| `minio.twoja-domena.pl` | 24581 | MinIO Console |

3. U swojego dostawcy DNS dodaj rekordy **CNAME** wskazujace na adres Elestio:

```
n8n.twoja-domena.pl      CNAME  twoja-domena.elestio.app
nocodb.twoja-domena.pl   CNAME  twoja-domena.elestio.app
minio.twoja-domena.pl    CNAME  twoja-domena.elestio.app
```

> Elestio automatycznie wygeneruje certyfikaty SSL dla Twoich subdomen.

## Pliki

| Plik | Opis |
|------|------|
| `docker-compose.yml` | Konfiguracja Docker (wklej do Elestio) |
| `.env.example` | Szablon zmiennych srodowiskowych |
| `README.md` | Ta instrukcja |
