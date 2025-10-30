#!/usr/bin/env bash
#shellcheck disable=SC2249
set -euo pipefail

# Inputs
INV="${INV:-$(find ~/quickbox_backup/ -maxdepth 1 -name 'qb_inventory_*.json' -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -n1)}"
[ -f "${INV}" ] || { echo "Inventory JSON not found. Set INV=/path/to/qb_inventory.json" >&2; exit 1; }

DB="${DB:-/opt/quickbox/config/db/qbpro.db}"
[ -f "${DB}" ] || DB="/srv/quickbox/db/qbpro.db"
[ -f "${DB}" ] || { echo "QuickBox DB not found at /opt or /srv" >&2; exit 1; }

# Exclusions (no services)
EXCLUDE_RE='^(rutorrent|lecert)$'

echo "[i] Building service name map from DB..."
declare -A SVC
while IFS=$'\t' read -r NAME SERVICE; do
  [[ -z "${NAME:-}" ]] && continue
  NAME="${NAME,,}"; SERVICE="${SERVICE,,}"
  [[ -z "${SERVICE}" || "${SERVICE}" == "null" ]] && SERVICE="${NAME}"
  SVC["${NAME}"]="${SERVICE}"
done < <(sqlite3 -tabs "${DB}" \
  "SELECT software_name, COALESCE(software_service_name, software_name)
   FROM software_information;")

echo "[i] Discovering user/application services from API..."
mapfile -t UA < <(
  jq -r '
    .data
    | to_entries[]
    | .value as $v
    | $v.user_information.username as $user
    | ($v.installed_software // $v.user_information.installed_software)
    | keys[]? as $app
    | [$user, $app]
    | @tsv
  ' "${INV}" | sort -u
)

stop_quiet() {
  local unit="$1"
  systemctl stop "${unit}" >/dev/null 2>&1 || true
}

echo "[i] Stopping dashboard layer..."
stop_quiet "nginx.service"
# Stop any php-fpm variants if present
systemctl list-units --all --type=service 'php*-fpm.service' --no-legend 2>/dev/null \
  | awk '{print $1}' | while read -r u; do stop_quiet "${u}"; done

echo "[i] Stopping per-user application services..."
WSD_DONE=0
for row in "${UA[@]}"; do
  USER="${row%%$'\t'*}"
  APP="${row#*$'\t'}"
  APP_LC="${APP,,}"
  [[ "${APP_LC}" =~ ${EXCLUDE_RE} ]] && continue

  svc="${SVC[${APP_LC}]:-${APP_LC}}"

  case "${APP_LC}" in
    wsdashboard)
      if (( WSD_DONE == 0 )); then
        stop_quiet "qbwsd.service"
        stop_quiet "qbwsd-log-server.service"
        WSD_DONE=1
      fi
      continue
      ;;
    webconsole)
      stop_quiet "ttyd@${USER}.service"
      stop_quiet "ttyd.service"
      continue
      ;;
    deluge)
      # daemon + web (cover templated and singleton)
      stop_quiet "deluged@${USER}.service"
      stop_quiet "deluged.service"
      stop_quiet "deluge-web@${USER}.service"
      stop_quiet "deluge-web.service"
      continue
      ;;
  esac

  # Generic: try templated first, then singleton
  stop_quiet "${svc}@${USER}.service"
  stop_quiet "${svc}.service"
done

echo "[✓] Service stop pass complete."