#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[update]${NC} $*"; }
warn()  { echo -e "${YELLOW}[update]${NC} $*"; }
error() { echo -e "${RED}[update]${NC} $*" >&2; }

if [[ ! -f .env ]]; then
  error ".env nicht gefunden."; exit 1
fi
source .env

COMPOSE_FILES="-f docker-compose.yml"
[[ -n "${LETSENCRYPT_HOST:-}" ]] && COMPOSE_FILES="${COMPOSE_FILES} -f docker-compose.https.yml"
[[ "${ENABLE_V2:-false}" == "true" ]] && COMPOSE_FILES="${COMPOSE_FILES} -f docker-compose.v2.yml"

ROLLBACK_FILE=".rollback_tag"

save_rollback_tag() {
  local running_image
  running_image=$(docker inspect calserver-app --format '{{.Config.Image}}' 2>/dev/null || true)
  if [[ -n "$running_image" ]]; then
    echo "$running_image" > "$ROLLBACK_FILE"
    info "Rollback-Tag gesichert: ${running_image}"
  fi
}

if [[ -n "${DOCKER_USERNAME:-}" && -n "${DOCKER_TOKEN:-}" ]]; then
  echo "${DOCKER_TOKEN}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
fi

rollback() {
  if [[ ! -f "$ROLLBACK_FILE" ]]; then
    error "Kein Rollback-Tag vorhanden. Manueller Eingriff nötig."
    return 1
  fi
  local rollback_image
  rollback_image=$(cat "$ROLLBACK_FILE")
  warn "Rollback auf: ${rollback_image}"
  export APP_VERSION="${rollback_image##*:}"
  docker compose $COMPOSE_FILES up -d --remove-orphans
  error "Update fehlgeschlagen – Rollback durchgeführt auf ${rollback_image}."
  exit 1
}

save_rollback_tag

info "Neue Images werden gepullt (Version: ${APP_VERSION:-latest}) ..."
if ! docker compose $COMPOSE_FILES pull; then
  error "Pull fehlgeschlagen."
  rollback
fi

info "Container werden neu gestartet ..."
if ! docker compose $COMPOSE_FILES up -d --remove-orphans; then
  error "Start fehlgeschlagen."
  rollback
fi

sleep 8
if ! docker ps --filter "name=calserver-app" --filter "status=running" | grep -q calserver-app; then
  error "App-Container nicht gestartet nach Update."
  rollback
fi

if [[ -x ./migration.sh ]]; then
  info "Datenbank-Migrationen werden ausgeführt ..."
  ./migration.sh || warn "Migration gab einen Fehler zurück – bitte manuell prüfen."
fi

info "Veraltete Images werden entfernt ..."
docker image prune -f --filter "until=24h" 2>/dev/null || true

info "Update abgeschlossen."
