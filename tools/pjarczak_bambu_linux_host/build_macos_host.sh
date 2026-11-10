#!/bin/sh
# Build the native macOS bridge host and optionally sign it.
#   PJARCZAK_CODESIGN_IDENTITY="Developer ID Application: Name (TEAMID)" sh build_macos_host.sh
# Installs to ~/Library/Application Support/OrcaSlicer/macos-bridge/pjarczak_bambu_mac_host (PJARCZAK_MAC_HOST_INSTALL_DIR overrides)
set -eu
here=$(cd "$(dirname "$0")" && pwd)
build=${PJARCZAK_MAC_HOST_BUILD_DIR:-"$here/.build-macos-host"}
brew_prefix=$(brew --prefix 2>/dev/null || echo /opt/homebrew)

cmake -S "$here" -B "$build" -DCMAKE_BUILD_TYPE=Release \
  -DOPENSSL_ROOT_DIR="$brew_prefix/opt/openssl@3" -DOPENSSL_USE_STATIC_LIBS=TRUE \
  -DBoost_ROOT="$brew_prefix/opt/boost"
cmake --build "$build" --target pjarczak_bambu_mac_host -j

bin="$build/tools/pjarczak_bambu_linux_host/pjarczak_bambu_mac_host"
if [ -n "${PJARCZAK_CODESIGN_IDENTITY:-}" ]; then
  codesign --force --timestamp --options runtime \
    --entitlements "$here/pjarczak_bambu_mac_host.entitlements" \
    --sign "$PJARCZAK_CODESIGN_IDENTITY" "$bin"
  codesign --verify --strict --verbose=2 "$bin"
fi
install_dir=${PJARCZAK_MAC_HOST_INSTALL_DIR:-"$HOME/Library/Application Support/OrcaSlicer/macos-bridge"}
mkdir -p "$install_dir"
cp -p "$bin" "$install_dir/pjarczak_bambu_mac_host"
echo "$install_dir/pjarczak_bambu_mac_host"
