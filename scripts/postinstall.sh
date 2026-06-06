#!/bin/bash

set -e

echo "[native.cr] Post-install setup"

# Detect OS
OS=$(uname -s)

# Create lib directory
mkdir -p lib/native

# Get latest version from GitHub
LATEST_VERSION=$(curl -s https://api.github.com/repos/slick-lab/native.cr/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)

if [ -z "$LATEST_VERSION" ]; then
    LATEST_VERSION="v0.1.0"
fi

# Only download Android prebuilt libraries on non-macOS
if [[ "$OS" != "Darwin" ]]; then
    echo "[native.cr] Downloading prebuilt Android libraries from $LATEST_VERSION..."
    
    curl -L -o lib/native/libnative_cr.so \
        "https://github.com/slick-lab/native.cr/releases/download/$LATEST_VERSION/libnative_cr.so"
    
    curl -L -o lib/native/libnative_cr_engine.so \
        "https://github.com/slick-lab/native.cr/releases/download/$LATEST_VERSION/libnative_cr_engine.so"
    
    echo "[native.cr] Android libraries saved to lib/native/"
else
    echo "[native.cr] macOS detected - skipping Android library download"
    echo "[native.cr] For Android builds, use Linux or Windows"
fi

echo "[native.cr] Post-install complete"
