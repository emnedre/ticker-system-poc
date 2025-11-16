#!/bin/bash
set -e

echo "Packaging Lambda functions..."

# Create lambda directory if it doesn't exist
mkdir -p lambda

# Package connect function
cd lambda
echo "Packaging connect function..."
zip -q connect.zip connect.py
echo "✓ connect.zip created"

# Package disconnect function
echo "Packaging disconnect function..."
zip -q disconnect.zip disconnect.py
echo "✓ disconnect.zip created"

# Package processor function (with dependencies)
echo "Packaging processor function..."
rm -rf package
mkdir -p package
pip install -r requirements.txt -t package/ --quiet
cd package
zip -qr ../processor.zip .
cd ..
zip -q processor.zip processor.py
rm -rf package
echo "✓ processor.zip created"

cd ..
echo "✓ All Lambda functions packaged successfully"
