#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${GREEN}[install]${NC} $*"; }
warn()  { echo -e "${YELLOW}[install]${NC} $*"; }
error() { echo -e "${RED}[install]${NC} $*" >&2; }

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     calserver-yii V1 – Installer        ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

command -v docker >/dev/null 2>&1 || { error "Docker fehlt. Installation: https://docs.docker.com/engine/install/ubuntu/"; exit 1; }
docker compose version >/dev/null 2>&1 || { error "Docker Compose Plugin fehlt."; exit 1; }
info "Docker $(docker --version | awk '{print $3}' | tr -d ',') gefunden."

if [[ ! -f .env ]]; then
  cp .env.example .env
  warn ".env aus Vorlage erstellt – bitte Werte anpassen."
fi

echo ""
echo -e "${BOLD}  Domain (z.B. calendar.example.com):${NC}"
read -r DOMAIN
echo -e "${BOLD}  E-Mail für Let's Encrypt:${NC}"
read -r EMAIL
echo -e "${BOLD}  Docker Hub Benutzername (vom Support):${NC}"
read -r DH_USER
echo -e "${BOLD}  Docker Hub Token (vom Support):${NC}"
read -r -s DH_TOKEN
echo ""

sed -i "s|VIRTUAL_HOST=.*|VIRTUAL_HOST=${DOMAIN}|g" .env
sed -i "s|LETSENCRYPT_HOST=.*|LETSENCRYPT_HOST=${DOMAIN}|g" .env
sed -i "s|LETSENCRYPT_EMAIL=.*|LETSENCRYPT_EMAIL=${EMAIL}|g" .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DOCKER_USERNAME=.*|DOCKER_USERNAME=${DH_USER}|g" .env
sed -i "s|DOCKER_TOKEN=.*|DOCKER_TOKEN=${DH_TOKEN}|g" .env

if grep -q "CHANGE_ME_GENERATE" .env; then
  APP_KEY="base64:$(openssl rand -base64 32)"
  sed -i "s|LARAVEL_APP_KEY=.*|LARAVEL_APP_KEY=${APP_KEY}|g" .env
  info "App Key generiert."
fi

echo ""
info "Installation wird gestartet ..."
bash deploy.sh

echo ""
echo -e "${GREEN}${BOLD}Installation abgeschlossen!${NC}"
echo ""
echo "  Nächste Schritte:"
echo "   - Status prüfen:    ./check.sh"
echo "   - Update:           ./update.sh"
echo "   - Logs:             docker logs calserver-app -f"
echo ""
