#!/bin/bash

# Script to securely setup API keys for iOS build
# This script reads from .env file and updates Info.plist

set -e

# Path to the .env file
ENV_FILE="${SRCROOT}/../../.env"
PLIST_FILE="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Info.plist"
SOURCE_PLIST="${SRCROOT}/Runner/Info.plist"

echo "🔐 Setting up secure API keys..."

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "⚠️ .env file not found at $ENV_FILE"
    echo "⚠️ Using fallback API key"
    exit 0
fi

# Read API key from .env file
GOOGLE_MAPS_API_KEY=$(grep "GOOGLE_MAPS_API_KEY_IOS" "$ENV_FILE" | cut -d '=' -f2)

if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
    echo "⚠️ GOOGLE_MAPS_API_KEY_IOS not found in .env file"
    echo "⚠️ Using fallback API key"
    exit 0
fi

echo "✅ Found Google Maps API key in .env"
echo "✅ API Key (masked): ${GOOGLE_MAPS_API_KEY:0:8}***"

# Update the built Info.plist if it exists
if [ -f "$PLIST_FILE" ]; then
    /usr/libexec/PlistBuddy -c "Set :GMSApiKey $GOOGLE_MAPS_API_KEY" "$PLIST_FILE" 2>/dev/null || true
    echo "✅ Updated runtime Info.plist with secure API key"
fi

echo "🔐 API key setup completed"
