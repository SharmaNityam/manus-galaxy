#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
secrets_file="$project_root/.local-secrets.json"

if [[ ! -f "$secrets_file" ]]; then
  echo "Missing .local-secrets.json. Add CHAT_PROVIDER and the matching API key." >&2
  exit 1
fi

provider="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("CHAT_PROVIDER", "gemini"))' "$secrets_file")"
cd "$project_root"

case "$provider" in
  openrouter)
    api_key="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("OPENROUTER_API_KEY", ""))' "$secrets_file")"
    if [[ -z "$api_key" ]]; then
      echo "OPENROUTER_API_KEY is missing from .local-secrets.json." >&2
      exit 1
    fi
    exec flutter run --dart-define=CHAT_PROVIDER=openrouter --dart-define="OPENROUTER_API_KEY=$api_key" "$@"
    ;;
  gemini)
    api_key="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("GEMINI_API_KEY", ""))' "$secrets_file")"
    if [[ -z "$api_key" ]]; then
      echo "GEMINI_API_KEY is missing from .local-secrets.json." >&2
      exit 1
    fi
    exec flutter run --dart-define=CHAT_PROVIDER=gemini --dart-define="GEMINI_API_KEY=$api_key" "$@"
    ;;
  mock)
    exec flutter run --dart-define=CHAT_PROVIDER=mock "$@"
    ;;
  *)
    echo "CHAT_PROVIDER must be openrouter, gemini, or mock." >&2
    exit 1
    ;;
esac
