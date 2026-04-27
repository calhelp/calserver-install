#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[migration]${NC} $*"; }
error() { echo -e "${RED}[migration]${NC} $*" >&2; }

source .env 2>/dev/null || true

COMPOSE_FILES="-f docker-compose.yml"
[[ -n "${LETSENCRYPT_HOST:-}" ]] && COMPOSE_FILES="${COMPOSE_FILES} -f docker-compose.https.yml"
[[ "${ENABLE_V2:-false}" == "true" ]] && COMPOSE_FILES="${COMPOSE_FILES} -f docker-compose.v2.yml"

RUNNING=$(docker compose $COMPOSE_FILES ps --services --filter status=running 2>/dev/null || true)

if echo "$RUNNING" | grep -q "^app$"; then
  info "Laravel Migrationen (V1) ..."
  docker compose $COMPOSE_FILES exec app php artisan migrate --force
  info "V1 Migrationen abgeschlossen."
else
  error "App-Service läuft nicht – Migration übersprungen."
  exit 1
fi

if [[ "${ENABLE_V2:-false}" == "true" ]]; then
  if echo "$RUNNING" | grep -q "^calserver-api-v2$"; then
    info "V2 API Migrationen ..."
    docker compose $COMPOSE_FILES exec calserver-api-v2 php artisan migrate --force
    info "V2 Migrationen abgeschlossen."
  else
    error "calserver-api-v2 läuft nicht – V2 Migration übersprungen."
  fi
fi

info "Alle Migrationen fertig."
