#!/bin/bash
set -e

IMAGE_TAG=${1:-latest}
AWS_REGION=${AWS_REGION:-us-west-2}

echo "=== Deploying SiPeKa (tag: $IMAGE_TAG) ==="

# Get ECR registry
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Pull images
echo "Pulling images..."
docker pull $ECR_REGISTRY/sipeka-backend:$IMAGE_TAG
docker pull $ECR_REGISTRY/sipeka-frontend:$IMAGE_TAG

# Stop existing containers
echo "Stopping existing containers..."
docker stop frontend backend 2>/dev/null || true
docker rm frontend backend 2>/dev/null || true

# Fetch secrets from SSM
echo "Fetching secrets from SSM..."
DB_HOST=$(aws ssm get-parameter --name /sipeka/db/host --query 'Parameter.Value' --output text --region $AWS_REGION)
DB_USER=$(aws ssm get-parameter --name /sipeka/db/user --query 'Parameter.Value' --output text --region $AWS_REGION)
DB_PASSWORD=$(aws ssm get-parameter --name /sipeka/db/password --with-decryption --query 'Parameter.Value' --output text --region $AWS_REGION)
SESS_SECRET=$(aws ssm get-parameter --name /sipeka/sess/secret --with-decryption --query 'Parameter.Value' --output text --region $AWS_REGION)

# Create network
docker network create sipeka-net 2>/dev/null || true

# Start backend
echo "Starting backend..."
docker run -d --name backend --network sipeka-net --restart unless-stopped \
    -e DB_HOST=$DB_HOST -e DB_USER=$DB_USER -e DB_PASSWORD=$DB_PASSWORD \
    -e DB_NAME=db_penggajian3 -e SESS_SECRET=$SESS_SECRET \
    -e APP_PORT=5000 -e NODE_ENV=production -e CORS_ORIGIN=* \
    -p 5000:5000 \
    $ECR_REGISTRY/sipeka-backend:$IMAGE_TAG

# Start frontend
echo "Starting frontend..."
docker run -d --name frontend --network sipeka-net --restart unless-stopped \
    -p 80:8080 -p 443:8443 \
    -v /etc/letsencrypt:/etc/nginx/ssl:ro \
    -v /home/ubuntu/nginx-ssl.conf:/etc/nginx/conf.d/default.conf:ro \
    $ECR_REGISTRY/sipeka-frontend:$IMAGE_TAG

# Wait and verify
sleep 10
if curl -sf http://localhost:5000/health > /dev/null; then
    echo "=== Deployment successful! ==="
else
    echo "=== WARNING: Health check failed, check logs ==="
    docker logs backend --tail 20
    exit 1
fi
