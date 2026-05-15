# Telegram Reboot Alert

Send a Telegram message whenever a Linux machine boots or restarts.

The user only needs to run `install.sh` or `uninstall.sh`. The installer asks for the Telegram bot token, chat ID, and machine description interactively. It also handles cleanup, file installation, permissions, service creation, enabling, and starting.

## Why This Exists

This script was created for development VMs that use DHCP and may get a different IP address after every restart.

In my workflow, these VMs are used for development and are often cloned, modified, tested, destroyed, and cloned again from a template. When a VM starts with a new DHCP address, it is annoying to manually check the IP address by opening the host machine, opening the VM console, logging in, and then inspecting the network configuration.

Instead, this service sends the VM's current IP information to Telegram every time the machine starts. That way, as soon as the VM boots, I already know which IP address to use for SSH, development, testing, or remote access.

## Features

- One-command install with `bash install.sh`
- One-command uninstall with `bash uninstall.sh`
- Prompts for Telegram bot token, chat ID, and machine description during install
- Cleans old installation before installing again
- Creates the config file automatically with secure permissions
- Installs the alert script automatically
- Installs, enables, and starts the `systemd` service automatically
- Uninstall removes the service and installed `/opt/telegram-reboot-alert` directory
- Does not save the sudo password

## Files

- `install.sh` - interactive reset-and-install script
- `uninstall.sh` - cleanup script
- `send-alert.sh` - alert script installed by `install.sh`
- `telegram-reboot-alert.service` - `systemd` service installed by `install.sh`
- `config.env.example` - example only, not required for normal install

## Requirements

- Linux with `systemd`
- `bash`
- `sudo`
- `curl`
- `ip` from `iproute2`
- Telegram bot token
- Telegram chat ID

## Telegram Setup

1. Create a bot with Telegram `@BotFather`.
2. Copy the bot token.
3. Send at least one message to your bot from the Telegram account or group that should receive alerts.
4. Get your chat ID.

One common way to get the chat ID is to open this URL after messaging the bot:

```text
https://api.telegram.org/botYOUR_BOT_TOKEN/getUpdates
```

Look for `chat.id` in the response.

## Install

Clone the project on the target Linux machine:

```bash
git clone https://github.com/andyp14feb/info_on_reboot.git
cd info_on_reboot
```

Run the installer:

```bash
bash install.sh
```

The installer will:

- Ask for sudo access first
- Ask for Telegram bot token
- Ask for Telegram chat ID
- Ask for machine description
- Remove any old `telegram-reboot-alert.service`
- Remove any old `/opt/telegram-reboot-alert` installation
- Install fresh files
- Create `/opt/telegram-reboot-alert/config.env` automatically
- Set secure config permissions automatically
- Enable and start the service automatically

You do not need to manually edit config files, copy code, run `chmod`, or run `systemctl` commands during normal installation.

## Reinstall

Run the installer again:

```bash
bash install.sh
```

Every install starts by cleaning the old installation if it exists, then creates a fresh installation using the values you enter.

## Uninstall

Run:

```bash
bash uninstall.sh
```

The uninstaller will:

- Ask for sudo access first
- Stop and disable `telegram-reboot-alert.service` if it exists
- Remove `/etc/systemd/system/telegram-reboot-alert.service`
- Remove `/opt/telegram-reboot-alert`
- Reload `systemd`
- Reset failed service state

## Sudo Password

The scripts request sudo access using `sudo -v` before privileged operations.

The sudo password is handled by `sudo` itself. The scripts do not read, store, print, or save the sudo password.

You can run the scripts as a normal user:

```bash
bash install.sh
bash uninstall.sh
```

You do not need to run them with `sudo bash ...`.

## Installed Paths

After installation:

- Config file: `/opt/telegram-reboot-alert/config.env`
- Alert script: `/opt/telegram-reboot-alert/send-alert.sh`
- Service file: `/etc/systemd/system/telegram-reboot-alert.service`
- Service name: `telegram-reboot-alert.service`

## Check Status

```bash
sudo systemctl status telegram-reboot-alert.service --no-pager
```

## Check Logs

```bash
sudo journalctl -u telegram-reboot-alert.service -n 80 --no-pager
```

## Restart Service

```bash
sudo systemctl restart telegram-reboot-alert.service
```

## Troubleshooting

If no Telegram message arrives, check logs first:

```bash
sudo journalctl -u telegram-reboot-alert.service -n 80 --no-pager
```

Common causes:

- Wrong Telegram bot token
- Wrong Telegram chat ID
- The bot has not received any message from you first
- The machine has no internet connection when the service runs
- `curl` is not installed
- `ip` command is not installed
- The system does not use `systemd`

## Security

Do not commit real Telegram credentials.

The installer writes credentials only to:

```text
/opt/telegram-reboot-alert/config.env
```

That file is created with `600` permissions, so only root can read it.
