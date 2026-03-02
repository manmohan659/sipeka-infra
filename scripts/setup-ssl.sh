#!/bin/bash
set -e

DOMAIN=${1:?Usage: setup-ssl.sh <domain>}
EMAIL=${2:-admin@$DOMAIN}

echo "=== SSL Setup for $DOMAIN ==="

if ! command -v certbot &> /dev/null; then
    echo "Installing Certbot..."
    apt-get update
    apt-get install -y certbot
fi

# Stop nginx container temporarily to free port 80
docker stop frontend 2>/dev/null || true

# Get certificate
certbot certonly --standalone \
    -d "$DOMAIN" \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    --http-01-port 80

echo "Certificate obtained for $DOMAIN"
echo "Cert location: /etc/letsencrypt/live/$DOMAIN/"

# Set up auto-renewal cron
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --pre-hook 'docker stop frontend' --post-hook 'docker start frontend' --quiet") | sort -u | crontab -

echo "Auto-renewal cron job configured"
echo "Restart your frontend container with SSL config now"
