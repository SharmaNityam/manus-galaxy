# Day 1 progress snapshot

This note is the original Day 1 checkpoint. The current build and final handoff status are documented in [handoff.md](handoff.md); this snapshot is retained to show the original scope and decisions.

## Shipped slice

- Responsive home, chat, composer, history drawer, keyboard handling, and jump-to-latest behavior.
- Gemini-compatible and OpenRouter streaming adapters, plus a deterministic mock for offline development and demonstrations.
- Markdown replies with tables, fenced code, horizontal code scrolling, and copy action.
- Stream stop preserves partial text; request generations isolate stale events; failed and stopped replies can be retried.
- Hive persistence for conversations, messages, partial replies, and a bounded message cache. Interrupted streams recover to a stopped state.
- Durable ordered outbox for offline sends and history rename, pin, and delete actions. The included mock history server honors operation IDs and demonstrates last-write-wins title conflict handling.
- Connectivity-triggered replay and visible sync status with manual retry.
- Two architecture decision records document streaming lifecycle, local persistence, cache invalidation, conflict policy, and mock-backend idempotency limits.

## Current verification

- `flutter analyze`: clean.
- `flutter test`: 12 tests pass across stream lifecycle, targeted retry, offline replay/conflicts, Gemini SSE parsing, OpenRouter SSE parsing, Markdown layout, and Hive recovery/cache invalidation.
- `dart format --output=none --set-exit-if-changed lib test`: clean.
- `git diff --check`: clean.
- Android release APK: built with the local trial signing key, verified, installed, and launched on a Pixel 9 Pro API 35 emulator.
- iOS simulator: built, installed, and launched on the iPhone 18 Pro simulator.
- Physical-device iPhone distribution and the assignment-length demo remain outstanding; see [handoff.md](handoff.md).

## Backend and security notes

Without a configured API key, a live provider shows an inline setup error; the deterministic mock must be selected explicitly. The history backend is a local Hive-backed fake service. It honors stable operation IDs for this demo, but client-generated IDs cannot guarantee exactly-once execution against a real server without server-side deduplication. Do not commit API keys.
