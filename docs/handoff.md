# Handoff status

## Delivered in this workspace

- [x] Responsive Flutter app with home, Ask/Agent mode picker, chat, composer, and searchable local history with archive/unarchive.
- [x] Streamed chat, cancellation, preserved partial replies, Markdown tables and code blocks, retry UI, and stale-request generation guards.
- [x] Local transcript persistence and interrupted-stream recovery.
- [x] Offline send, rename, pin, archive, and delete queue with stable operation IDs, ordered replay, sync status, and mock-server deduplication.
- [x] Cache invalidation and last-write-wins conflict policy documented in ADRs.
- [x] Gemini-compatible and OpenRouter streaming adapters; deterministic mock is explicitly selectable. Missing live credentials produce a setup error instead of a fabricated answer.
- [x] Private Android release signing configuration. The release variant does not use the debug certificate.
- [x] `flutter analyze` and 28 passing Flutter tests on 16 October 2026.
- [x] Connectivity loss cancels an active stream immediately, keeps partial text, and leaves the reply retryable.
- [x] Verified the home screen and composer with the Android emulator at 360 dp, including the soft keyboard, with no visible overflow.
- [x] Signed Android release APK built and verified; app installed and launched on the Pixel 9 Pro API 35 emulator.
- [x] iOS simulator build installed and launched on the iPhone 18 Pro simulator (iOS 27).
- [x] iOS simulator app bundle is archived locally at `handoff/ManusGalaxy-iOS-Simulator.app.zip`.
- [x] Compared the signed-in Manus Android app and this app side by side on the 360 dp emulator; adjusted the new-chat screen and history drawer colors and layout.
- [x] Reproducible local hydration observation recorded in [performance.md](performance.md).
- [x] Companion walkthrough at `../handoff/manus-galaxy-day2.mp4` (58 seconds).

- [x] Native Add to chat, camera/photo/file selection, saved attachment Library, recent-task context, skills, connector catalogue/detail/manage routes, and microphone dictation controls. See [native-composer.md](native-composer.md).
- [x] Attachments persist with messages and survive queued replay and explicit retry. Follow-up requests receive preceding conversation turns.

## Device and distribution limits

- Android emulator coverage was recorded in the reviewer video. The signed-in Manus comparison was completed on the emulator. No Android phone is currently connected. The iPhone is listed by Xcode but unavailable, so physical-device checks and a side-by-side comparison against Manus on physical phones remain outstanding.
- The Android APK in `handoff/` is signed with a locally generated trial certificate. The private key and passwords are ignored by Git and must be retained locally to sign future updates. Replace it with the hiring team's release key if they provide one.
- The iOS simulator build runs. A signed device IPA and TestFlight upload require an Apple Developer provisioning profile; none is installed in this workspace. The physical iPhone is unavailable.
- The chat history service is a deterministic local mock. OpenRouter or Gemini provides streamed assistant replies; the history mock is not a production backend.
- OpenRouter is pinned to Gemma 4 31B Free to keep ordinary chat on a consistent model after a prior router response contained only a safety label. The latest live request returned HTTP 429, so the selected model's response could not be reverified during this pass. Retry after the provider's free-tier limit clears.
- Physical-device performance and the cross-platform physical-device comparison remain unverified. The durable outbox restart test closes and reopens Hive, then simulates an ambiguous server acknowledgement and confirms that redelivery does not duplicate a mutation. This is automated crash-recovery evidence, not a recorded OS force-kill during a live replay.
- The companion video is shorter than the assignment's requested 5–7 minute final demo. A full-length walkthrough still needs to be recorded.

## Reviewer walkthrough

The short video demonstrates composing with the emulator keyboard, a streamed response with a Markdown table and code, opening local history, queuing a send while offline, and the sync state after reconnecting. The complete repository includes setup steps, architecture, two ADRs, test commands, and release signing instructions.

## Before a production release

Use a server-side credential proxy, connect a real history backend with an idempotency contract, sign with the team's Android and Apple release credentials, verify on physical Android and iPhone devices, and capture a reproducible performance trace with device and build details.
