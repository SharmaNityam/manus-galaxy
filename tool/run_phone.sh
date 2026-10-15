#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

flutter pub get
flutter build web --release --dart-define=CHAT_PROVIDER=mock
cd build/web
exec python3 -m http.server 8080 --bind 0.0.0.0
