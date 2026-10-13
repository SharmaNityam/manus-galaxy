# Work trial progress

## Working in the current build

- Reference-informed responsive home, chat, composer, history drawer, keyboard handling, and jump-to-latest behavior.
- Mock streaming and optional Gemini-compatible SSE streaming configured with `GEMINI_API_KEY` at build time.
- Markdown replies with tables, fenced code, horizontal code scrolling, and copy action.
- Stream stop preserves partial text; request generations isolate stale events; failed and stopped replies can be retried.
- Hive persistence for conversations, messages, partial replies, and a bounded message cache. Interrupted streams recover to a stopped state.
- Durable ordered outbox for offline sends and history rename, pin, and delete actions. The included mock history server honors operation IDs and demonstrates last-write-wins title conflict handling.
- Connectivity-triggered replay and visible sync status with manual retry.
- Two architecture decision records document streaming lifecycle, local persistence, cache invalidation, conflict policy, and the mock backend's idempotency limits.

## Verification completed

- `flutter test`: 11 tests pass across stream lifecycle, targeted retry, offline replay/conflicts, Gemini SSE parsing, Markdown layout, and Hive recovery/cache invalidation.
- `flutter analyze`: no issues found.
- `git diff --check`: clean.
- `flutter build apk --debug`: succeeds.
- Android emulator: launched the app, sent a prompt, verified streamed Markdown table and code block, disabled connectivity, queued an offline prompt, restored connectivity, confirmed it replayed into a response, force-stopped/reopened the app, and confirmed conversation history remained available.

## Remaining before handoff

- Validate on the connected physical Android phone and a real iPhone. The iOS simulator build currently fails during Flutter framework architecture packaging, so iOS runtime behavior is not yet verified.
- Run the full conflict and offline queue demonstration on a real backend or the deterministic mock, including force-kill between queued operations.
- Produce the release-signed Android APK, installable iOS build, reproducible performance observation, and demo video.
- Compare more screens and interaction details against the live Manus app and address remaining visual differences.
- The Gemini adapter now defaults to the current stable `gemini-3.8-flash` model and sends the documented `x-goog-api-key` header. The supplied key returned HTTP 401 on two small direct REST checks, including against 3.8 Flash. The APK was rebuilt without a key; emulator verification uses the deterministic mock until a working Gemini credential is available.

## Backend and security notes

Without `GEMINI_API_KEY`, chat uses the deterministic mock. The history backend is a local Hive-backed fake service. It honors stable operation IDs for this demo, but client-generated IDs cannot guarantee exactly-once behavior against a real server without server-side deduplication. Do not commit a real API key.
