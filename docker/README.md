# Docker Stacks

Konfiguracje Docker do kursu z automatyzacji.

## Dostepne stacki

| Stack | Opis | Uslugi |
|-------|------|--------|
| [course_local_stack](course_local_stack/) | Wersja lokalna (bez SSL) | n8n, NocoDB, MinIO, Qdrant, PostgreSQL, Redis |
| [course_vps_stack](course_vps_stack/) | Pelna wersja VPS (z workerami) | Caddy + wszystkie uslugi |
| [course_vps_stack_light](course_vps_stack_light/) | Light VPS (bez workerow) | Caddy, n8n, NocoDB, MinIO, Qdrant, PostgreSQL, Redis |
| [course_vps_n8n_with_workers](course_vps_n8n_with_workers/) | Tylko n8n + workers | Caddy, n8n, PostgreSQL, Redis |
| [course_vps_n8n_without_workers](course_vps_n8n_without_workers/) | Tylko n8n (bez workerow) | Caddy, n8n, PostgreSQL, Redis |
| [course_vps_nocodb](course_vps_nocodb/) | Tylko NocoDB + MinIO | Caddy, NocoDB, MinIO, PostgreSQL, Redis |
| [course_vps_qdrant](course_vps_qdrant/) | Tylko Qdrant | Caddy, Qdrant |

## Ktory wybrac?

- **Nauka lokalna** → `course_local_stack`
- **Pelne wdrozenie VPS** → `course_vps_stack`
- **Pelne wdrozenie VPS (mniejszy serwer)** → `course_vps_stack_light`
- **Tylko automatyzacje (n8n) z workerami** → `course_vps_n8n_with_workers`
- **Tylko automatyzacje (n8n) bez workerow** → `course_vps_n8n_without_workers`
- **Tylko baza no-code** → `course_vps_nocodb`
- **Tylko vector DB (RAG)** → `course_vps_qdrant`

## Szybki start

```bash
# Wejdz do wybranego stacka
cd course_local_stack  # lub inny

# Uruchom inicjalizacje
./init_local_stack.sh  # local
./init.sh              # VPS

# Uruchom stack
docker compose up -d
```

## Porownanie

| Cecha | Local | VPS pelny | VPS light | n8n+workers | n8n (no workers) | nocodb | qdrant |
|-------|-------|-----------|-----------|-------------|-----------------|--------|--------|
| SSL | Brak | Tak | Tak | Tak | Tak | Tak | Tak |
| RAM | ~4GB | ~6GB | ~4GB | ~2GB | ~1.5GB | ~2GB | ~2.5GB |
| Domeny | localhost | 5 | 4 | 1 | 1 | 2 | 1 |
| Queue mode | Tak | Tak | Nie | Tak | Nie | - | - |

## Adresy (local stack)

- n8n: http://localhost:5678
- NocoDB: http://localhost:8080
- MinIO: http://localhost:9001
- Qdrant: http://localhost:6333/dashboard
