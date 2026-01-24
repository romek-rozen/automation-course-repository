# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Opis projektu

Repozytorium z konfiguracjami Docker do kursu z automatyzacji.

## Dostepne stacki

| Stack | Opis |
|-------|------|
| `docker/course_local_stack/` | Wersja lokalna (bez SSL, localhost) |
| `docker/course_vps_stack/` | Pelna wersja VPS (Caddy + SSL) |
| `docker/course_vps_n8n_with_workers/` | Uproszczony VPS (tylko n8n + workers) |
| `docker/course_vps_nocodb/` | Uproszczony VPS (tylko NocoDB + MinIO) |
| `docker/course_vps_qdrant/` | Uproszczony VPS (tylko Qdrant) |

## Szczegoly techniczne

Pelna dokumentacja techniczna (architektura, komendy, porty, konfiguracja) znajduje sie w:
- [docker/CLAUDE.md](docker/CLAUDE.md) - szczegoly dla Claude
- [docker/README.md](docker/README.md) - dokumentacja dla uzytkownikow
