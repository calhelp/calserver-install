#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
fail() { echo -e "  ${RED}✗${NC} $*"; ERRORS=$((ERRORS+1)); }
warn() { echo -e "  ${YELLOW}!${NC} $*"; }

ERRORS=0

echo ""
echo "=== calserver Health Check ==="
echo ""

# ── Container-Status ──────────────────────────────────────────────
CONTAINERS=(calserver-app calserver-mysql nginx-proxy)

[[ "${ENABLE_V2:-false}" == "true" ]] && CONTAINERS+=(calserver-api-v2 calserver-frontend)

for name in "${CONTAINERS[@]}"; do
  if docker ps --filter "name=${name}" --filter "status=running" | grep -q "${name}"; then
    ok "${name} läuft"
  else
    fail "${name} ist NICHT gestartet"
  fi
done

echo ""

# ── HTTP Erreichbarkeit ───────────────────────────────────────────
source .env 2>/dev/null || true
HOST="${VIRTUAL_HOST:-localhost}"

if command -v curl >/dev/null 2>&1; then
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://${HOST}/health" 2>/dev/null || echo "000")
  if [[ "$HTTP_CODE" =~ ^(200|301|302|401|403)$ ]]; then
    ok "HTTP ${HTTP_CODE} von https://${HOST}/health"
  else
    warn "HTTP ${HTTP_CODE} von https://${HOST}/health (erwartet 2xx/3xx)"
  fi
fi

# ── Festplattenspeicher ────────────────────────────────────────────
echo ""
DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | tr -d '%')
if [[ "$DISK_USAGE" -gt 85 ]]; then
  fail "Festplatte zu ${DISK_USAGE}% belegt – bitte aufräumen!"
elif [[ "$DISK_USAGE" -gt 70 ]]; then
  warn "Festplatte zu ${DISK_USAGE}% belegt."
else
  ok "Festplatte zu ${DISK_USAGE}% belegt."
fi

# ── Docker Volumes ────────────────────────────────────────────────
echo ""
echo "  Docker Volumes:"
docker volume ls --filter "name=calserver" --format "    {{.Name}}" 2>/dev/null || true

echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo -e "${RED}${ERRORS} Problem(e) gefunden.${NC}"
  exit 1
else
  echo -e "${GREEN}Alles OK.${NC}"
fi
echo ""
