#!/bin/bash
set -e

echo "🚀 Deploying Ticker System POC"
echo "================================"

# Step 1: Package Lambda functions
echo ""
echo "Step 1: Packaging Lambda functions..."
./scripts/package-lambdas.sh

# Step 2: Initialize Terraform
echo ""
echo "Step 2: Initializing Terraform..."
terraform init

# Step 3: Plan Terraform deployment
echo ""
echo "Step 3: Planning Terraform deployment..."
terraform plan -out=tfplan

# Step 4: Apply Terraform
echo ""
echo "Step 4: Applying Terraform..."
terraform apply tfplan

# Step 5: Build and push producer image
echo ""
echo "Step 5: Building and pushing producer Docker image..."
./scripts/build-producer.sh

# Step 6: Initialize tickers table
echo ""
echo "Step 6: Initializing tickers table..."
./scripts/init-tickers.sh

# Step 7: Update ECS service to use new image
echo ""
echo "Step 7: Updating ECS service..."
aws ecs update-service \
    --cluster ticker-system-poc-cluster \
    --service ticker-system-poc-producer \
    --force-new-deployment \
    --region us-east-1 > /dev/null

# Step 8: Get outputs
echo ""
echo "Step 8: Getting deployment outputs..."
WEBSOCKET_URL=$(terraform output -raw websocket_url)
WEBSITE_URL=$(terraform output -raw website_url)

# Step 9: Generate frontend configuration
echo ""
echo "Step 9: Generating frontend configuration..."
cat > frontend/config.generated.js << EOF
// Auto-generated configuration - DO NOT EDIT MANUALLY
window.APP_CONFIG = {
    WEBSOCKET_URL: '${WEBSOCKET_URL}'
};
EOF

# Step 10: Upload frontend to S3
echo ""
echo "Step 9: Uploading frontend to S3..."
BUCKET_NAME=$(aws s3 ls | grep ticker-system-poc-website | awk '{print $3}')
aws s3 cp frontend/index.html s3://${BUCKET_NAME}/index.html --content-type "text/html"
aws s3 cp frontend/config.generated.js s3://${BUCKET_NAME}/config.js --content-type "application/javascript"

# Step 11: Invalidate CloudFront cache
echo ""
echo "Step 10: Invalidating CloudFront cache..."
DISTRIBUTION_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment==''].Id" --output text)
aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths "/*" > /dev/null

echo ""
echo "================================"
echo "✓ Deployment completed successfully!"
echo ""
echo "📊 Access your ticker system:"
echo "   Website: https://${WEBSITE_URL}"
echo "   WebSocket: ${WEBSOCKET_URL}"
echo ""
echo "⏱️  Note: CloudFront distribution may take 10-15 minutes to fully deploy"
