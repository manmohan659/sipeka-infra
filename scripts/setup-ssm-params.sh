#!/bin/bash
set -e

AWS_REGION=${AWS_REGION:-us-west-2}

echo "=== Setting up SSM Parameters for SiPeKa ==="
echo "Region: $AWS_REGION"
echo ""

read -p "RDS Endpoint: " DB_HOST
read -p "DB Username: " DB_USER
read -sp "DB Password: " DB_PASSWORD
echo ""
read -sp "Session Secret: " SESS_SECRET
echo ""

aws ssm put-parameter --name "/sipeka/db/host" --value "$DB_HOST" --type "String" --overwrite --region $AWS_REGION
aws ssm put-parameter --name "/sipeka/db/user" --value "$DB_USER" --type "String" --overwrite --region $AWS_REGION
aws ssm put-parameter --name "/sipeka/db/password" --value "$DB_PASSWORD" --type "SecureString" --overwrite --region $AWS_REGION
aws ssm put-parameter --name "/sipeka/sess/secret" --value "$SESS_SECRET" --type "SecureString" --overwrite --region $AWS_REGION

echo ""
echo "=== SSM Parameters configured ==="
aws ssm describe-parameters --filters "Key=Name,Values=/sipeka/" --region $AWS_REGION --query 'Parameters[].Name' --output table
