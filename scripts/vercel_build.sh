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
EXTRA_ARGS=()
if [ -n "${SUPABASE_URL:-}" ]; then
  EXTRA_ARGS+=(--dart-define="SUPABASE_URL=${SUPABASE_URL}")
fi
if [ -n "${SUPABASE_ANON_KEY:-}" ]; then
  EXTRA_ARGS+=(--dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}")
fi

flutter build web --release --base-href / "${EXTRA_ARGS[@]}"

echo "==> Build completed successfully! Output in build/web"
