#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./scripts/scale-tickers.sh <number_of_tickers>"
    echo "Example: ./scripts/scale-tickers.sh 8"
    echo ""
    echo "Available tickers: 20 (AAPL, TSLA, GOOGL, MSFT, AMZN, META, NVDA, AMD, NFLX, DIS, PYPL, INTC, CSCO, ADBE, CRM, ORCL, IBM, UBER, LYFT, SPOT)"
    exit 1
fi

TICKER_COUNT=$1

if [ "$TICKER_COUNT" -gt 20 ]; then
    echo "⚠️  Maximum 20 tickers available. Setting to 20."
    TICKER_COUNT=20
fi

echo "Scaling to ${TICKER_COUNT} active tickers..."

# Update ECS service desired count
terraform apply -var="producer_task_count=${TICKER_COUNT}" -auto-approve

echo "✓ Scaled to ${TICKER_COUNT} tickers"
echo "⏱️  ECS tasks are starting..."
echo ""
echo "View active tickers:"
echo "  aws ecs list-tasks --cluster ticker-system-poc-cluster --service ticker-system-poc-producer"
