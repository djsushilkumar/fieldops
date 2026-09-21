#!/usr/bin/env bash
# FieldOps Vercel Automated Build Script
set -euo pipefail

echo "==> Preparing Flutter SDK on Vercel build container..."
if [ ! -d "/tmp/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b 3.24.5 --depth 1 /tmp/flutter
fi

export PATH="/tmp/flutter/bin:$PATH"

echo "==> Verifying Flutter version..."
flutter --version

echo "==> Installing dependencies..."
flutter pub get

echo "==> Building Flutter Web application..."
flutter build web --release --base-href /

echo "==> Build completed successfully! Output in build/web"
