#!/bin/bash
# Downloads and compiles Dear ImGui + cimgui with SDL2 + OpenGL3 backends
# Output: vendor/imgui/lib/libimgui_native.a + headers

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
VENDOR_DIR="$ROOT_DIR/vendor/imgui"
SRC_DIR="$VENDOR_DIR/src"
LIB_DIR="$VENDOR_DIR/lib"
INC_DIR="$VENDOR_DIR/include"

if [ -f "$LIB_DIR/libimgui_native.a" ]; then
  echo "[imgui] Already built, skipping."
  exit 0
fi

mkdir -p "$SRC_DIR" "$LIB_DIR" "$INC_DIR"

IMGUI_VERSION="1.90.9"
IMGUI_URL="https://github.com/ocornut/imgui/archive/refs/tags/v${IMGUI_VERSION}.tar.gz"

echo "[imgui] Downloading Dear ImGui v${IMGUI_VERSION}..."
curl -L "$IMGUI_URL" -o "$SRC_DIR/imgui.tar.gz"
tar -xf "$SRC_DIR/imgui.tar.gz" -C "$SRC_DIR" --strip-components=1
rm "$SRC_DIR/imgui.tar.gz"

echo "[imgui] Locating SDL2..."
SDL2_CFLAGS=$(sdl2-config --cflags 2>/dev/null || echo "-I/usr/include/SDL2")
SDL2_LIBS=$(sdl2-config --libs 2>/dev/null || echo "-lSDL2")

echo "[imgui] SDL2 CFLAGS: $SDL2_CFLAGS"

echo "[imgui] Compiling imgui core..."
CXX_FLAGS="-std=c++17 -O2 -fPIC $SDL2_CFLAGS \
  -I$SRC_DIR \
  -I$SRC_DIR/backends \
  -DIMGUI_IMPL_OPENGL_LOADER_CUSTOM"

OBJECTS=()

# Core ImGui
g++ $CXX_FLAGS -c "$SRC_DIR/imgui.cpp" -o "$SRC_DIR/imgui.o"
g++ $CXX_FLAGS -c "$SRC_DIR/imgui_draw.cpp" -o "$SRC_DIR/imgui_draw.o"
g++ $CXX_FLAGS -c "$SRC_DIR/imgui_tables.cpp" -o "$SRC_DIR/imgui_tables.o"
g++ $CXX_FLAGS -c "$SRC_DIR/imgui_widgets.cpp" -o "$SRC_DIR/imgui_widgets.o"
g++ $CXX_FLAGS -c "$SRC_DIR/imgui_demo.cpp" -o "$SRC_DIR/imgui_demo.o"

# Backends
g++ $CXX_FLAGS -c "$SRC_DIR/backends/imgui_impl_sdl2.cpp" -o "$SRC_DIR/imgui_impl_sdl2.o"
g++ $CXX_FLAGS -c "$SRC_DIR/backends/imgui_impl_opengl3.cpp" -o "$SRC_DIR/imgui_impl_opengl3.o"

# Our C backend wrapper
g++ $CXX_FLAGS -c "$SCRIPT_DIR/backend.cpp" -o "$SRC_DIR/backend.o"

echo "[imgui] Archiving static library..."
ar rcs "$LIB_DIR/libimgui_native.a" \
  "$SRC_DIR/imgui.o" \
  "$SRC_DIR/imgui_draw.o" \
  "$SRC_DIR/imgui_tables.o" \
  "$SRC_DIR/imgui_widgets.o" \
  "$SRC_DIR/imgui_demo.o" \
  "$SRC_DIR/imgui_impl_sdl2.o" \
  "$SRC_DIR/imgui_impl_opengl3.o" \
  "$SRC_DIR/backend.o"

echo "[imgui] Copying headers..."
cp "$SRC_DIR/imgui.h" "$INC_DIR/"
cp "$SRC_DIR/imgui_internal.h" "$INC_DIR/"
cp "$SRC_DIR/imconfig.h" "$INC_DIR/"
cp "$SRC_DIR/imstb_rectpack.h" "$INC_DIR/"
cp "$SRC_DIR/imstb_textedit.h" "$INC_DIR/"
cp "$SRC_DIR/imstb_truetype.h" "$INC_DIR/"
cp "$SRC_DIR/backends/imgui_impl_sdl2.h" "$INC_DIR/"
cp "$SRC_DIR/backends/imgui_impl_opengl3.h" "$INC_DIR/"
cp "$SCRIPT_DIR/backend.h" "$INC_DIR/"

echo "[imgui] Build complete! Library at: $LIB_DIR/libimgui_native.a"
