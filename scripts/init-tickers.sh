#!/bin/bash
set -e

TABLE_NAME="ticker-system-poc-tickers"
REGION="us-east-1"

echo "Initializing tickers table..."

# Function to put item
put_ticker() {
    local symbol=$1
    local name=$2
    local price=$3
    
    aws dynamodb put-item \
        --table-name ${TABLE_NAME} \
        --item "{
            \"symbol\": {\"S\": \"${symbol}\"},
            \"name\": {\"S\": \"${name}\"},
            \"initialPrice\": {\"N\": \"${price}\"}
        }" \
        --region ${REGION} > /dev/null
    
    echo "  ✓ ${symbol} - ${name} (\$${price})"
}

# Add all tickers
put_ticker "AAPL" "Apple Inc." "180"
put_ticker "TSLA" "Tesla Inc." "250"
put_ticker "GOOGL" "Alphabet Inc." "140"
put_ticker "MSFT" "Microsoft Corp." "380"
put_ticker "AMZN" "Amazon.com Inc." "150"
put_ticker "META" "Meta Platforms Inc." "350"
put_ticker "NVDA" "NVIDIA Corp." "500"
put_ticker "AMD" "Advanced Micro Devices" "120"
put_ticker "NFLX" "Netflix Inc." "450"
put_ticker "DIS" "Walt Disney Co." "95"
put_ticker "PYPL" "PayPal Holdings" "65"
put_ticker "INTC" "Intel Corp." "45"
put_ticker "CSCO" "Cisco Systems" "52"
put_ticker "ADBE" "Adobe Inc." "550"
put_ticker "CRM" "Salesforce Inc." "220"
put_ticker "ORCL" "Oracle Corp." "110"
put_ticker "IBM" "IBM Corp." "155"
put_ticker "UBER" "Uber Technologies" "70"
put_ticker "LYFT" "Lyft Inc." "15"
put_ticker "SPOT" "Spotify Technology" "180"

echo ""
echo "✓ Initialized 20 tickers"
