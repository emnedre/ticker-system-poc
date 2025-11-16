#!/bin/bash
set -e

# Get AWS account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REPO="ticker-system-poc-producer"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"

echo "Building and pushing producer Docker image..."
echo "ECR Repository: ${ECR_URI}"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build Docker image for ARM64
echo "Building Docker image for ARM64..."
cd producer
docker buildx build --platform linux/arm64 -t ${ECR_REPO}:latest .

# Tag image
echo "Tagging image..."
docker tag ${ECR_REPO}:latest ${ECR_URI}:latest

# Push to ECR
echo "Pushing to ECR..."
docker push ${ECR_URI}:latest

cd ..
echo "✓ Producer image built and pushed successfully"
echo "Image URI: ${ECR_URI}:latest"
