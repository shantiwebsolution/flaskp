#!/bin/bash
# Enable strict mode and robust logging for web server userdata
set -euo pipefail

# Log files
LOG=/var/log/web_userdata.log
CLOUD_LOG=/var/log/cloud-init-output.log
GLOBAL_USERDATA_LOG=/var/log/userdata.log

# Ensure logfile exists and is writable
mkdir -p /var/log
touch "$LOG" "$CLOUD_LOG" "$GLOBAL_USERDATA_LOG"
chmod 600 "$LOG" || true
chown root:root "$LOG" || true

# Redirect stdout/stderr to both the web userdata log and cloud-init output (and console)
exec > >(tee -a "$LOG" "$CLOUD_LOG" "$GLOBAL_USERDATA_LOG") 2>&1

echo "Web userdata script started at $(date)"

# Trap errors and log the failing command, exit code and timestamp to logs
trap 'err=$?; cmd="$BASH_COMMAND"; echo "ERROR: Command \"$cmd\" exited with $err at $(date)" | tee -a "$LOG" "$CLOUD_LOG" "$GLOBAL_USERDATA_LOG" >&2' ERR

# Update system packages
apt update && apt upgrade -y

# Install and start nginx
apt install -y nginx
systemctl enable nginx
systemctl start nginx

echo "Web server setup completed" | tee -a "$LOG" "$CLOUD_LOG" "$GLOBAL_USERDATA_LOG"
