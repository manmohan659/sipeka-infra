#!/bin/bash
set -ex

# Update system
apt-get update -y
apt-get install -y docker.io awscli curl

# Start Docker
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configure AWS CLI for ECR access (uses instance role)
echo "EC2 instance ready for deployment"
