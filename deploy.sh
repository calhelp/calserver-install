#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[deploy]${NC} $*"; }
warn()    { echo -e "${YELLOW}[deploy]${NC} $*"; }
error()   { echo -e "${RED}[deploy]${NC} $*" >&2; }

if [[ ! -f .env ]]; then
  error ".env nicht gefunden. Bitte zuerst .env einrichten (Vorlage: .env.example)."
  exit 1
fi

source .env

command -v docker >/dev/null 2>&1 || { error "Docker ist nicht installiert."; exit 1; }
docker compose version >/dev/null 2>&1 || { error "Docker Compose Plugin nicht gefunden."; exit 1; }

if [[ -n "${DOCKER_USERNAME:-}" && -n "${DOCKER_TOKEN:-}" ]]; then
  info "Docker Hub Login als ${DOCKER_USERNAME} ..."
  echo "${DOCKER_TOKEN}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
else
  warn "DOCKER_USERNAME / DOCKER_TOKEN nicht gesetzt – überspringe Login."
fi

COMPOSE_FILES="-f docker-compose.yml"

if [[ -n "${LETSENCRYPT_HOST:-}" ]]; then
  info "Let's Encrypt aktiviert für: ${LETSENCRYPT_HOST}"
  COMPOSE_FILES="${COMPOSE_FILES} -f docker-compose.https.yml"
fi

if [[ "${ENABLE_V2:-false}" == "true" ]]; then
  info "V2 Stack aktiviert."
  COMPOSE_FILES="${COMPOSE_FILES} -f docker-compose.v2.yml"
fi

docker network inspect proxy >/dev/null 2>&1 || docker network create proxy
docker network inspect calserver-internal >/dev/null 2>&1 || docker network create calserver-internal

mkdir -p nginx/conf.d nginx/vhost.d mysql/conf.d

info "Images werden gepullt ..."
docker compose $COMPOSE_FILES pull

info "Stack wird gestartet ..."
docker compose $COMPOSE_FILES up -d --remove-orphans

info "Warte auf App-Container ..."
sleep 5
if docker compose $COMPOSE_FILES ps --services --filter status=running | grep -q "^app$"; then
  info "App läuft."
else
  error "App ist nicht gestartet. Logs:"
  docker compose $COMPOSE_FILES logs app --tail 30
  exit 1
fi

info "Deployment abgeschlossen."
echo ""
echo -e "  URL: ${GREEN}https://${VIRTUAL_HOST:-localhost}${NC}"
echo ""
