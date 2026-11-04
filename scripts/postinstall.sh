#!/bin/bash

# native.cr postinstall — downloads the prebuilt CLI and platform libraries.
#
# Safety properties (all downloads):
#   * curl -fL — an HTTP 404 aborts instead of writing an error page to
#     disk as a fake object file (the failure mode GPT's review flagged).
#   * sha256 verification against scripts/CHECKSUMS — a corrupted or
#     tampered artifact fails the install rather than linking into apps.
#
# Pinning policy: libgc/libpcre stay on v0.1.6 DELIBERATELY. Those two
# archives are the Boehm GC and PCRE static libs; they change rarely and
# v0.1.6 is the last build that was linked against the exact runtime
# versions the Android/iOS engines expect. Bumping them requires
# re-validating the engines, so the pin is explicit, not accidental.

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
VERSION=$(curl -fs https://api.github.com/repos/slick-lab/native.cr/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)

if [ -z "$VERSION" ]; then
  VERSION="v0.1.8"
fi

echo "[native.cr] Latest version: $VERSION"

# The pinned GC/PCRE pair (see pinning policy in the header comment).
GC_PCRE_VERSION="v0.1.6"

# Checksum manifests, one per release the artifacts come from.
CHECKSUMS_CURRENT="https://github.com/slick-lab/native.cr/releases/download/$VERSION/CHECKSUMS"
CHECKSUMS_PINNED="https://github.com/slick-lab/native.cr/releases/download/$GC_PCRE_VERSION/CHECKSUMS"

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

# fetch_and_verify <output-path> <url> <checksums-url>
# Downloads with -f (hard fail on 404s) and verifies the sha256 against
# the given release's CHECKSUMS file. Missing checksum entry => hard
# failure: nothing gets linked into user apps unverified.
fetch_and_verify() {
  local out="$1"
  local url="$2"
  local sums_url="$3"
  local expected
  local sums="checksums-$(basename "$(dirname "$sums_url")").tmp"

  curl -fL -o "$out" "$url" || { echo "[native.cr] FAILED download: $url" >&2; return 1; }

  if [ ! -f "$sums" ]; then
    curl -fL -o "$sums" "$sums_url" || {
      echo "[native.cr] FAILED to download CHECKSUMS from $sums_url — refusing to install unverified artifacts" >&2
      return 1
    }
  fi

  local base
  base=$(basename "$out")
  expected=$(grep -E "[[:space:]]$base\$" "$sums" | head -1 | awk '{print $1}')
  if [ -z "$expected" ]; then
    echo "[native.cr] No checksum recorded for $base in release $VERSION — refusing unverified artifact" >&2
    return 1
  fi

  local actual
  if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "$out" | awk '{print $1}')
  elif command -v shasum >/dev/null 2>&1; then
    actual=$(shasum -a 256 "$out" | awk '{print $1}')
  else
    echo "[native.cr] Neither sha256sum nor shasum available — cannot verify downloads" >&2
    return 1
  fi

  if [ "$actual" != "$expected" ]; then
    echo "[native.cr] CHECKSUM MISMATCH for $base (expected $expected, got $actual) — aborting" >&2
    return 1
  fi
  echo "[native.cr] verified $base"
}

# Download binary
BINARY_URL="https://github.com/slick-lab/native.cr/releases/download/$VERSION/native.cr-${OS}-${ARCH}"
OUTPUT_PATH="$INSTALL_DIR/native.cr"

echo "[native.cr] Downloading from: $BINARY_URL"

fetch_and_verify "$OUTPUT_PATH" "$BINARY_URL" "$CHECKSUMS_CURRENT"
chmod +x "$OUTPUT_PATH"
echo "[native.cr] CLI installed successfully"

# Create lib directory for prebuilt libraries
mkdir -p lib/native

# Download Android libraries
echo ""
echo "[native.cr] Downloading Android prebuilt libraries..."

fetch_and_verify lib/native/native_engine.o \
  "https://github.com/slick-lab/native.cr/releases/download/$VERSION/native_engine.o" \
  "$CHECKSUMS_CURRENT"

fetch_and_verify lib/native/libnative_cr_android.jar \
  "https://github.com/slick-lab/native.cr/releases/download/$VERSION/libnative_cr_android.jar" \
  "$CHECKSUMS_CURRENT"

# Pinned pair, verified against THEIR OWN release's checksums.
fetch_and_verify lib/native/libgc.a \
  "https://github.com/slick-lab/native.cr/releases/download/$GC_PCRE_VERSION/libgc.a" \
  "$CHECKSUMS_PINNED"

fetch_and_verify lib/native/libpcre.a \
  "https://github.com/slick-lab/native.cr/releases/download/$GC_PCRE_VERSION/libpcre.a" \
  "$CHECKSUMS_PINNED"

echo "[native.cr] Android libraries downloaded"

# Download iOS libraries (only on macOS)
if [ "$OS" = "darwin" ]; then
  echo ""
  echo "[native.cr] Downloading iOS prebuilt libraries..."

  fetch_and_verify lib/native/libnative_cr_ios.a \
    "https://github.com/slick-lab/native.cr/releases/download/$VERSION/libnative_cr_ios.a" \
    "$CHECKSUMS_CURRENT"

  # libgc.a / libpcre.a are already installed above from the pinned pair;
  # the duplicate downloads from the old script are gone.
  echo "[native.cr] iOS libraries downloaded"
fi

rm -f checksums-*.tmp

echo ""
echo "[native.cr] Post-install complete!"
echo "[native.cr] Run 'native.cr doctor' to verify setup"

# Add to PATH if needed
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "[native.cr] Add $INSTALL_DIR to your PATH"
fi
