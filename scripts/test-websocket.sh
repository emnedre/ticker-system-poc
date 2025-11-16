#!/bin/bash
set -e

# Get WebSocket URL from Terraform
WS_URL=$(terraform output -raw websocket_url 2>/dev/null)

if [ -z "$WS_URL" ]; then
    echo "Error: Could not get WebSocket URL from Terraform"
    echo "Make sure you've deployed the infrastructure first"
    exit 1
fi

echo "Connecting to: $WS_URL"
echo "Press CTRL+C to quit"
echo ""

# Check if wscat is installed
if command -v wscat &> /dev/null; then
    wscat -c "$WS_URL"
# Check if websocat is installed
elif command -v websocat &> /dev/null; then
    if command -v jq &> /dev/null; then
        websocat "$WS_URL" | jq .
    else
        websocat "$WS_URL"
    fi
# Fall back to Python
elif command -v python3 &> /dev/null; then
    python3 << EOF
import asyncio
import websockets
import json
import sys

async def connect():
    uri = '$WS_URL'
    try:
        async with websockets.connect(uri) as ws:
            print('✓ Connected!', file=sys.stderr)
            print('', file=sys.stderr)
            async for message in ws:
                data = json.loads(message)
                print(json.dumps(data, indent=2))
    except KeyboardInterrupt:
        print('\nDisconnected', file=sys.stderr)
    except Exception as e:
        print(f'Error: {e}', file=sys.stderr)
        sys.exit(1)

asyncio.run(connect())
EOF
else
    echo "Error: No WebSocket client found"
    echo "Please install one of: wscat, websocat, or python3"
    echo ""
    echo "Install wscat: npm install -g wscat"
    echo "Install websocat: brew install websocat"
    exit 1
fi
