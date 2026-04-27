#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[migration]${NC} $*"; }
error() { echo -e "${RED}[migration]${NC} $*" >&2; }

if docker ps --filter "name=calserver-app" --filter "status=running" | grep -q calserver-app; then
  info "Laravel Migrationen (V1) ..."
  docker exec calserver-app php artisan migrate --force
  info "V1 Migrationen abgeschlossen."
else
  error "calserver-app läuft nicht – Migration übersprungen."
  exit 1
fi

source .env 2>/dev/null || true

if [[ "${ENABLE_V2:-false}" == "true" ]]; then
  if docker ps --filter "name=calserver-api-v2" --filter "status=running" | grep -q calserver-api-v2; then
    info "V2 API Migrationen ..."
    docker exec calserver-api-v2 php artisan migrate --force
    info "V2 Migrationen abgeschlossen."
  else
    error "calserver-api-v2 läuft nicht – V2 Migration übersprungen."
  fi
fi

info "Alle Migrationen fertig."
