#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

[[ ! -f .env ]] && { echo "Fehler: .env nicht gefunden."; exit 1; }
source .env

COMPOSE_FILES="-f docker-compose.yml"
[[ -n "${LETSENCRYPT_HOST:-}" ]] && COMPOSE_FILES="${COMPOSE_FILES} -f docker-compose.https.yml"
[[ "${ENABLE_V2:-false}" == "true" ]] && COMPOSE_FILES="${COMPOSE_FILES} -f docker-compose.v2.yml"

echo "Stack wird neu gestartet ..."
docker compose $COMPOSE_FILES restart
echo "Fertig."
