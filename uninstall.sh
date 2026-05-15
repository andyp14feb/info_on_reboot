#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="telegram-reboot-alert.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
INSTALL_DIR="/opt/telegram-reboot-alert"

echo "Telegram Reboot Alert uninstaller"
echo
echo "Sudo access is required to remove the systemd service and installed files."
echo "Your sudo password may be requested by sudo and is not saved by this script."
sudo -v

if [[ ! -t 0 ]]; then
  echo "This uninstaller must be run from an interactive terminal." >&2
  exit 1
fi

sudo systemctl disable --now "${SERVICE_NAME}" 2>/dev/null || true
sudo rm -f "${SERVICE_PATH}"
sudo rm -rf "${INSTALL_DIR}"
sudo systemctl daemon-reload
sudo systemctl reset-failed

echo
echo "Removed ${SERVICE_NAME} and ${INSTALL_DIR}."
