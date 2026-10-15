# Manus Galaxy

Manus Galaxy is a Flutter chat app built for a three-day mobile work trial. It focuses on a clean chat flow, streamed answers, saved conversations, and recovery when the network drops.

## Run the app

Install Flutter 3.35 or newer, then fetch the packages:

```sh
flutter pub get
```

For a live response, add the provider key to the ignored local secrets file and run `./tool/run_local.sh`. Keep keys out of source control. A mock provider is available for UI work:

```sh
flutter run --dart-define=CHAT_PROVIDER=mock
```

The app also supports Gemini-compatible and OpenRouter streaming providers. The selected provider and model can be configured at build or run time. A mobile app key is extractable, so a production service should put provider credentials behind a server-side proxy.

## What’s here

- New chat with Ask and Agent modes, suggestions, and a responsive composer
- Streamed chat with stop, retry, and Markdown rendering
- Local conversation history with search, rename, pin, archive, and delete
- Saved conversations and messages that remain available offline
- Queued history changes and sends that replay when the connection returns
- Attachment, connector, and voice input flows

## How it’s organized

The app separates presentation, domain, and data code. `go_router` handles navigation, Riverpod manages screen state, Hive stores local conversations and queued operations, and Dio handles network requests. The history service is a deterministic mock used to demonstrate ordered replay and duplicate-operation handling. Live assistant replies use the configured streaming provider.

The main design decisions are in [ADR 0001](docs/adr/0001-local-storage-and-sync.md) and [ADR 0002](docs/adr/0002-streaming-lifecycle.md). The architecture diagram is in [docs/architecture.excalidraw](docs/architecture.excalidraw).

## Check the project

```sh
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test
```

For a simulator build, run `flutter build ios --simulator`. See [docs/handoff.md](docs/handoff.md) for build notes, known limits, and verification details. A local performance observation is recorded in [docs/performance.md](docs/performance.md).

## Current limits

The history backend is local and mocked, so it does not sync across devices. The simulator build can be run without Apple signing; a device-installable IPA or TestFlight build needs an Apple Developer provisioning profile. Android release signing uses the local trial certificate, not a Play Store upload key.
