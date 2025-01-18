#!/bin/bash

CLOUDFLARE_IPS_V4_URL="https://www.cloudflare.com/ips-v4"
CLOUDFLARE_IPS_V6_URL="https://www.cloudflare.com/ips-v6"
CLOUDFLARE_IPS_V4="/etc/cloudflare-ips-v4"
CLOUDFLARE_IPS_V6="/etc/cloudflare-ips-v6"

error_exit() {
    echo "Error: $1"
    exit 1
}

log_message() {
    echo "[INFO] $1"
}

log_message "Checking firewalld installation..."
if ! command -v firewall-cmd &>/dev/null; then
    log_message "firewalld not found, installing..."
    sudo dnf install -y firewalld || error_exit "Failed to install firewalld"
fi

sudo systemctl enable --now firewalld || error_exit "Failed to start firewalld"

log_message "Downloading Cloudflare IP ranges..."
curl -s -o "$CLOUDFLARE_IPS_V4" "$CLOUDFLARE_IPS_V4_URL" || error_exit "Failed to download IPv4 list"
curl -s -o "$CLOUDFLARE_IPS_V6" "$CLOUDFLARE_IPS_V6_URL" || error_exit "Failed to download IPv6 list"

log_message "Creating Cloudflare zone in firewalld..."
sudo firewall-cmd --permanent --new-zone=cloudflare 2>/dev/null
sudo firewall-cmd --zone=cloudflare --set-target=ACCEPT --permanent || error_exit "Failed to create Cloudflare zone"

log_message "Adding Cloudflare IPs to the firewall..."
while read -r ip; do
    sudo firewall-cmd --zone=cloudflare --add-source="$ip" --permanent || error_exit "Failed to add $ip to Cloudflare zone"
done <"$CLOUDFLARE_IPS_V4"

while read -r ip; do
    sudo firewall-cmd --zone=cloudflare --add-source="$ip" --permanent || error_exit "Failed to add $ip to Cloudflare zone"
done <"$CLOUDFLARE_IPS_V6"

log_message "Setting default zone to drop all traffic..."
sudo firewall-cmd --set-default-zone=drop || error_exit "Failed to set default zone"

log_message "Reloading firewalld..."
sudo firewall-cmd --reload || error_exit "Failed to reload firewalld"

log_message "Setting up daily cron job to update Cloudflare IPs..."
CRON_JOB="/etc/cron.d/update-cloudflare-ips"
echo "0 3 * * * root curl -s -o $CLOUDFLARE_IPS_V4 $CLOUDFLARE_IPS_V4_URL && \
curl -s -o $CLOUDFLARE_IPS_V6 $CLOUDFLARE_IPS_V6_URL && \
firewall-cmd --reload" | sudo tee "$CRON_JOB" >/dev/null
sudo chmod 644 "$CRON_JOB"

log_message "Firewall setup complete. Only Cloudflare requests are now allowed."
