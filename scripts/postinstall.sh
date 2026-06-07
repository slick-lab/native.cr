#!/bin/bash

set -e

echo "[native.cr] Post-install setup"

# Detect OS
OS=$(uname -s)

# Create lib directory
mkdir -p lib/native

# Create bin directory
mkdir -p bin

# Get latest version from GitHub
LATEST_VERSION=$(curl -s https://api.github.com/repos/slick-lab/native.cr/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)

if [ -z "$LATEST_VERSION" ]; then
    LATEST_VERSION="v0.0.98"
fi

echo "[native.cr] Latest version: $LATEST_VERSION"

# Only download Android prebuilt libraries on non-macOS
if [[ "$OS" != "Darwin" ]]; then
    echo "[native.cr] Downloading prebuilt Android libraries..."
    
    curl -L -o lib/native/libnative_cr.so \
        "https://github.com/slick-lab/native.cr/releases/download/$LATEST_VERSION/libnative_cr.so"
    
    curl -L -o lib/native/libnative_cr_engine.so \
        "https://github.com/slick-lab/native.cr/releases/download/$LATEST_VERSION/libnative_cr_engine.so"
    
    echo "[native.cr] Android libraries saved to lib/native/"
else
    echo "[native.cr] macOS detected - skipping Android library download"
fi

# Build CLI using crystal build directly
echo "[native.cr] Building CLI..."
crystal build src/native.cr -o bin/native.cr --release

# Install CLI to user directory
mkdir -p ~/.local/bin
cp bin/native.cr ~/.local/bin/

# Add to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
    echo "[native.cr] Added ~/.local/bin to PATH in ~/.bashrc"
fi

# Source bashrc to update PATH in current session
if [[ -f ~/.bashrc ]]; then
    source ~/.bashrc
fi

echo "[native.cr] Post-install complete"
echo "[native.cr] Run 'native.cr doctor' to verify setup"
