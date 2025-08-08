#!/bin/bash
# Enable strict mode and robust logging
set -euo pipefail

# Log files
LOG=/var/log/userdata.log
CLOUD_LOG=/var/log/cloud-init-output.log

# Ensure logfile exists and is writable (keep permissive if chown/chmod fail)
mkdir -p /var/log
touch "$LOG" "$CLOUD_LOG"
chmod 600 "$LOG" || true
chown root:root "$LOG" || true

# Redirect all stdout/stderr to both the userdata log and cloud-init output (and to console)
# tee accepts multiple files; this will append to both logs
exec > >(tee -a "$LOG" "$CLOUD_LOG") 2>&1

echo "Userdata script started at $(date)"

# Trap errors and log the failing command, exit code and timestamp to both logs
trap 'err=$?; cmd="$BASH_COMMAND"; echo "ERROR: Command \"$cmd\" exited with $err at $(date)" | tee -a "$LOG" "$CLOUD_LOG" >&2' ERR

# Update system packages
apt update && apt upgrade -y

# Install Node.js via NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Also install the latest Node.js release (uses npm-based 'n' version manager)
# 1) install 'n' globally via npm (requires node/npm installed above)
# 2) use 'n' to install the latest stable Node.js
npm install -g n
n latest

# Install AWS CLI v2 (Debian/Ubuntu compatible installer)
# Ensure unzip is available for the official AWS CLI zip installer
apt install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
# Install to /usr/local and create symlinks in /usr/local/bin
./aws/install -i /usr/local/aws-cli -b /usr/local/bin
rm -rf awscliv2.zip aws

# Install Python 3.x and pip
apt install -y python3 python3-pip

# Install Docker Engine using the official Docker install script (ensures docker.service exists)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm -f get-docker.sh

# Add ubuntu user to docker group so the 'ubuntu' user can use docker without sudo
usermod -aG docker ubuntu

# Configure Docker to start on boot and start the service
systemctl enable docker
systemctl start docker


# Install SSM agent if not already installed
snap list amazon-ssm-agent || snap install amazon-ssm-agent --classic

# Start SSM agent
snap start amazon-ssm-agent
# Log installation completion

sudo mkdir -p /home/ubuntu/app
sudo chown -R ubuntu:ubuntu /home/ubuntu/app
cd /home/ubuntu/app

# Clone repository over HTTPS (avoids requiring SSH key in userdata)
git clone https://github.com/shantiwebsolution/flaskp.git || { echo "git clone failed"; exit 1; }

# Start frontend
cd flaskp/frontend2 || { echo "cd frontend2 failed"; exit 1; }
npm install
# Run frontend in background and log output
nohup node app.js > /var/log/frontend2.log 2>&1 &

# Start backend
cd ../backend || { echo "cd backend failed"; exit 1; }
pip3 install --no-cache-dir -r requirements.txt
nohup python3 app.py > /var/log/backend.log 2>&1 &

echo "App server setup completed" >> /var/log/userdata.log
