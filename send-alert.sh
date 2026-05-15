#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/opt/telegram-reboot-alert/config.env"
SCRIPT_FILE="/opt/telegram-reboot-alert/send-alert.sh"
SERVICE_FILE="/etc/systemd/system/telegram-reboot-alert.service"
RECONFIGURE_CMD="sudo nano ${CONFIG_FILE}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file not found: $CONFIG_FILE" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

: "${BOT_TOKEN:?BOT_TOKEN is required in $CONFIG_FILE}"
: "${CHAT_ID:?CHAT_ID is required in $CONFIG_FILE}"
: "${MACHINE_DESC:?MACHINE_DESC is required in $CONFIG_FILE}"

CURRENT_TIME="$(date '+%Y-%m-%d %H:%M:%S %Z')"
HOSTNAME_VALUE="$(hostname)"
UPTIME_VALUE="$(uptime -p || true)"

INTERFACES="$({
  ip -o -4 addr show | awk '{print "- " $2 " IPv4: " $4}'
  ip -o -6 addr show scope global | awk '{print "- " $2 " IPv6: " $4}'
} | sort)"

if [[ -z "${INTERFACES}" ]]; then
  INTERFACES="No IP address detected."
fi

MESSAGE="$(cat <<MSG
Machine rebooted / started

SYSTEM INFO
Date Time: ${CURRENT_TIME}
Hostname: ${HOSTNAME_VALUE}
Description: ${MACHINE_DESC}
Uptime: ${UPTIME_VALUE}

NETWORK INTERFACES
${INTERFACES}

SERVICE INFO
Config File: ${CONFIG_FILE}
Alert Script: ${SCRIPT_FILE}
Service File: ${SERVICE_FILE}

Reconfigure:
${RECONFIGURE_CMD}

Restart Service:
sudo systemctl restart telegram-reboot-alert.service

Check Logs:
sudo journalctl -u telegram-reboot-alert.service -n 50 --no-pager
MSG
)"

curl -sS -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${CHAT_ID}" \
  --data-urlencode "text=${MESSAGE}" \
  >/dev/null
