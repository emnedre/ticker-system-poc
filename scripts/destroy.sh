#!/bin/bash
set -e

echo "⚠️  WARNING: This will destroy all resources!"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo "Destroying infrastructure..."

# Empty S3 bucket first
BUCKET_NAME=$(aws s3 ls | grep ticker-system-poc-website | awk '{print $3}' || echo "")
if [ ! -z "$BUCKET_NAME" ]; then
    echo "Emptying S3 bucket..."
    aws s3 rm s3://${BUCKET_NAME} --recursive
fi

# Empty ECR repository
echo "Emptying ECR repository..."
aws ecr batch-delete-image \
    --repository-name ticker-system-poc-producer \
    --image-ids "$(aws ecr list-images --repository-name ticker-system-poc-producer --query 'imageIds[*]' --output json)" \
    --region us-east-1 2>/dev/null || echo "ECR repository already empty or doesn't exist"

# Destroy with Terraform
terraform destroy -auto-approve

echo "✓ All resources destroyed"
