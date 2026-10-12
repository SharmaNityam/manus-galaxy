# Day 1 progress

## Working

- Flutter app starts at a dark, chat-first home screen.
- A user can open a conversation and submit a prompt.
- The mock assistant response streams in chunks.
- Stop cancels the stream and retains the partial response.
- Conversations and messages are stored locally in Hive CE.
- The architecture separates presentation, domain, and data code.

## Not implemented yet

- Gemini-compatible live stream and key configuration
- Conversation history drawer and rename, pin, and delete actions
- Durable offline operation queue, replay, and conflict resolution
- Streaming Markdown renderer and inline retry
- iOS and Android device visual checks

## Evidence

- flutter analyze passes.
- Android debug APK builds.
- The connected Android device was unavailable at packaging time, so no physical-device install or capture is included.
- The iOS simulator build remains blocked by a Flutter framework architecture packaging error. No demo video is included.

## Next

Wire the real streaming adapter behind the existing repository contract, then build history and durable ordered offline replay. Keep the demo backend behavior and its idempotency limits explicit.
