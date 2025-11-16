#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./scripts/update-trade-frequency.sh <trades_per_second>"
    echo "Example: ./scripts/update-trade-frequency.sh 10"
    exit 1
fi

NEW_FREQUENCY=$1

echo "Updating trade frequency to ${NEW_FREQUENCY} trades/second..."

# Update Terraform variable
terraform apply -var="trade_frequency=${NEW_FREQUENCY}" -auto-approve

# Force ECS service to restart with new environment variable
echo "Restarting ECS service..."
aws ecs update-service \
    --cluster ticker-system-poc-cluster \
    --service ticker-system-poc-producer \
    --force-new-deployment \
    --region us-east-1 > /dev/null

echo "✓ Trade frequency updated to ${NEW_FREQUENCY} trades/second"
echo "⏱️  ECS service is restarting with new configuration..."
echo ""
echo "💡 Tip: To change number of tickers, run:"
echo "   terraform apply -var=\"producer_task_count=8\" -auto-approve"
