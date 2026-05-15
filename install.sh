#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="telegram-reboot-alert.service"
INSTALL_DIR="/opt/telegram-reboot-alert"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="${INSTALL_DIR}/config.env"

echo "Telegram Reboot Alert installer"
echo
echo "Sudo access is required to install the systemd service."
echo "Your sudo password may be requested by sudo and is not saved by this script."
sudo -v

if [[ ! -t 0 ]]; then
  echo "This installer must be run from an interactive terminal." >&2
  exit 1
fi

command -v curl >/dev/null || {
  echo "curl is required but was not found." >&2
  exit 1
}

command -v ip >/dev/null || {
  echo "ip command is required but was not found." >&2
  exit 1
}

read -r -p "Telegram bot token: " BOT_TOKEN
read -r -p "Telegram chat ID: " CHAT_ID
read -r -p "Machine description: " MACHINE_DESC

if [[ -z "${BOT_TOKEN}" || -z "${CHAT_ID}" || -z "${MACHINE_DESC}" ]]; then
  echo "Bot token, chat ID, and machine description are all required." >&2
  exit 1
fi

printf -v BOT_TOKEN_ESC '%q' "${BOT_TOKEN}"
printf -v CHAT_ID_ESC '%q' "${CHAT_ID}"
printf -v MACHINE_DESC_ESC '%q' "${MACHINE_DESC}"

echo
echo "Cleaning old installation if it exists..."
sudo systemctl disable --now "${SERVICE_NAME}" 2>/dev/null || true
sudo rm -f "${SERVICE_PATH}"
sudo rm -rf "${INSTALL_DIR}"
sudo systemctl daemon-reload
sudo systemctl reset-failed

echo "Installing files..."
sudo mkdir -p "${INSTALL_DIR}"
sudo install -m 755 "${PROJECT_DIR}/send-alert.sh" "${INSTALL_DIR}/send-alert.sh"

sudo install -m 600 /dev/null "${CONFIG_PATH}"
sudo tee "${CONFIG_PATH}" >/dev/null <<CONFIG
BOT_TOKEN=${BOT_TOKEN_ESC}
CHAT_ID=${CHAT_ID_ESC}
MACHINE_DESC=${MACHINE_DESC_ESC}
CONFIG
sudo chmod 600 "${CONFIG_PATH}"

sudo install -m 644 "${PROJECT_DIR}/telegram-reboot-alert.service" "${SERVICE_PATH}"
sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
sudo systemctl start "${SERVICE_NAME}"

echo
echo "Installed and started ${SERVICE_NAME}."
echo "Check logs: sudo journalctl -u ${SERVICE_NAME} -n 50 --no-pager"
