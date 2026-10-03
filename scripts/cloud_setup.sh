#!/usr/bin/env bash
# Cloud environment setup: installs Flutter (pinned to CI version) + Dart SDK.
# Paste into: environment menu > Edit > Setup script. Idempotent.
set -euo pipefail

FLUTTER_VERSION="3.47.0"   # keep in sync with .github/workflows
INSTALL_DIR="$HOME/.local/share"
FLUTTER_DIR="$INSTALL_DIR/flutter"

case "$(uname -m)" in
  x86_64)  DART_ARCH="x64" ;;
  aarch64) DART_ARCH="arm64" ;;
  *)       echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

mkdir -p "$INSTALL_DIR"

# 1. Flutter (bundles its own Dart, used by flutter analyze/test)
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "==> Installing Flutter $FLUTTER_VERSION..."
  rm -rf "$FLUTTER_DIR"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

# 2. Standalone Dart SDK (latest stable)
if [ ! -x "$INSTALL_DIR/dart-sdk/bin/dart" ]; then
  echo "==> Installing Dart SDK ($DART_ARCH)..."
  ZIP="/tmp/dart-sdk.zip"
  curl -sSL "https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-${DART_ARCH}-release.zip" -o "$ZIP"
  unzip -q "$ZIP" -d "$INSTALL_DIR"
  rm -f "$ZIP"
fi

# 3. PATH: symlink into /usr/local/bin (works in non-interactive shells too).
#    The Flutter-bundled dart is used for `dart`, so it matches the project SDK.
ln -sf "$FLUTTER_DIR/bin/flutter" /usr/local/bin/flutter
ln -sf "$FLUTTER_DIR/bin/dart"    /usr/local/bin/dart
ln -sf "$INSTALL_DIR/dart-sdk/bin/dart" /usr/local/bin/dart-standalone

# Also for interactive shells
for line in "export PATH=\"\$PATH:$FLUTTER_DIR/bin\""; do
  grep -qxF "$line" ~/.bashrc 2>/dev/null || echo "$line" >> ~/.bashrc
done

# 4. Warm up + project deps
export PATH="$PATH:$FLUTTER_DIR/bin"
flutter config --no-analytics >/dev/null 2>&1 || true
flutter --version
dart --version
dart-standalone --version
if [ -f pubspec.yaml ]; then flutter pub get; fi
