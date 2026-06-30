#!/bin/bash

set -e

echo "[native.cr] Post-install setup"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
  x86_64) ARCH="x86_64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) ARCH="x86_64" ;;
esac

echo "[native.cr] Detected OS: $OS, Arch: $ARCH"

# Get latest version from GitHub
VERSION=$(curl -s https://api.github.com/repos/slick-lab/native.cr/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)

if [ -z "$VERSION" ]; then
  VERSION="v0.1.2"
fi

echo "[native.cr] Latest version: $VERSION"

# Determine install directory
if [ -w "/usr/local/bin" ]; then
  INSTALL_DIR="/usr/local/bin"
elif [ -w "$HOME/.local/bin" ]; then
  INSTALL_DIR="$HOME/.local/bin"
else
  INSTALL_DIR="./bin"
  mkdir -p "$INSTALL_DIR"
fi

echo "[native.cr] Installing to: $INSTALL_DIR"

# Download binary
BINARY_URL="https://github.com/slick-lab/native.cr/releases/download/$VERSION/native.cr-${OS}-${ARCH}"
OUTPUT_PATH="$INSTALL_DIR/native.cr"

echo "[native.cr] Downloading from: $BINARY_URL"

if curl -L -o "$OUTPUT_PATH" "$BINARY_URL"; then
  chmod +x "$OUTPUT_PATH"
  echo "[native.cr] CLI installed successfully"
else
  echo "[native.cr] Failed to download pre-built binary"
  exit 1
fi

# Create lib directory for prebuilt libraries
mkdir -p lib/native

# Download Android libraries
echo ""
echo "[native.cr] Downloading Android prebuilt libraries..."

curl -L -o lib/native/native_engine.o \
  "https://github.com/slick-lab/native.cr/releases/download/$VERSION/native_engine.o"

curl -L -o lib/native/libnative_cr_android.jar \
  "https://github.com/slick-lab/native.cr/releases/download/$VERSION/libnative_cr_android.jar"

echo "[native.cr] Android libraries downloaded"

# Download iOS libraries (only on macOS)
if [ "$OS" = "darwin" ]; then
  echo ""
  echo "[native.cr] Downloading iOS prebuilt libraries..."

  curl -L -o lib/native/libnative_cr_engine.a \
    "https://github.com/slick-lab/native.cr/releases/download/$VERSION/libnative_cr_engine.a"

  curl -L -o lib/native/libnative_cr_ios.a \
    "https://github.com/slick-lab/native.cr/releases/download/$VERSION/libnative_cr_ios.a"

  echo "[native.cr] iOS libraries downloaded"
fi

echo ""
echo "[native.cr] Post-install complete!"
echo "[native.cr] Run 'native.cr doctor' to verify setup"

# Add to PATH if needed
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "[native.cr] Add $INSTALL_DIR to your PATH"
fi