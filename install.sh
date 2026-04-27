#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${GREEN}[install]${NC} $*"; }
warn()  { echo -e "${YELLOW}[install]${NC} $*"; }
error() { echo -e "${RED}[install]${NC} $*" >&2; }
ask()   { echo -e "${BOLD}$*${NC}"; }

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     calserver-yii V1 – Installer        ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── Voraussetzungen prüfen ────────────────────────────────────────
command -v docker >/dev/null 2>&1 || { error "Docker fehlt. Bitte Docker installieren: https://docs.docker.com/engine/install/ubuntu/"; exit 1; }
docker compose version >/dev/null 2>&1 || { error "Docker Compose Plugin fehlt."; exit 1; }
info "Docker $(docker --version | awk '{print $3}' | tr -d ',') gefunden."

# ── .env einrichten ───────────────────────────────────────────────
if [[ ! -f .env ]]; then
  warn ".env fehlt – wird aus Vorlage erstellt."
  cp .env .env.example 2>/dev/null || true
  cat .env | grep -v '^#' | grep -v '^$' || true
fi

info ".env bearbeiten? (Strg+C zum Abbrechen, Enter zum Fortfahren)"
echo ""
ask "  Domain (z.B. calendar.example.com):"
read -r DOMAIN
ask "  E-Mail für Let's Encrypt:"
read -r EMAIL
ask "  Docker Hub Benutzername (vom Support):"
read -r DH_USER
ask "  Docker Hub Token (vom Support):"
read -r -s DH_TOKEN
echo ""

# .env schreiben
sed -i "s|VIRTUAL_HOST=.*|VIRTUAL_HOST=${DOMAIN}|g" .env
sed -i "s|LETSENCRYPT_HOST=.*|LETSENCRYPT_HOST=${DOMAIN}|g" .env
sed -i "s|LETSENCRYPT_EMAIL=.*|LETSENCRYPT_EMAIL=${EMAIL}|g" .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DOCKER_USERNAME=.*|DOCKER_USERNAME=${DH_USER}|g" .env
sed -i "s|DOCKER_TOKEN=.*|DOCKER_TOKEN=${DH_TOKEN}|g" .env

# App Key generieren wenn noch Platzhalter
if grep -q "CHANGE_ME_GENERATE" .env; then
  APP_KEY="base64:$(openssl rand -base64 32)"
  sed -i "s|LARAVEL_APP_KEY=.*|LARAVEL_APP_KEY=${APP_KEY}|g" .env
  info "App Key generiert."
fi

# ── Deploy ausführen ──────────────────────────────────────────────
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
