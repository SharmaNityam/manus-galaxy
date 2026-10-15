# Native composer and interaction pass

The signed-in Manus Android app was inspected on the same 360 dp emulator as the replica. The comparison covered the new-chat composer, Add to chat sheet, connector menu, catalogue, connector detail, connector management, Library, and microphone permission and recording states.

## Behavior

- Add opens a dismissible half-height Add to chat sheet. Camera opens the native camera; Picture opens the native photo picker; File opens the native document picker. Cancel leaves the draft intact. Selected files have a removable preview and are saved in Library.
- Library supports search, image filtering, selection, and adding saved files to the draft. Recent tasks and Creations use local conversation content. Skills insert an editable task instruction.
- The cable button opens the connector menu. Add connectors opens a searchable catalogue with category filters; Manage connectors opens the empty connection-management state. Each connector opens its detail screen with external documentation links.
- Real third-party account authorization requires a registered OAuth service. Setting CONNECTOR_AUTH_BASE_URL to an HTTPS service enables an external /authorize/{connectorId} handoff. This build has no such service configured and shows that state when Connect is pressed. It never reports a fabricated connected account.
- Microphone opens native permission on first use, then an inline waveform and timer with cancel, confirm, and send. Confirm inserts recognized speech into the editable draft; send requires an explicit action. Silence, interruption, permission denial, and unavailable speech recognition have visible states. Recognition is provided by the device speech service and may require a network connection.
- Send remains disabled for an empty draft. All three composer actions also work in an active conversation.

## Data and API

Images, PDF files, and text documents are limited to four attachments per message, 5 MB each and 10 MB total. Attachment bytes are stored locally with the message; offline replay and explicit retry retain them. OpenRouter receives image content parts, decoded text documents, or PDF file parts. PDFs explicitly select the free Cloudflare parsing engine. Gemini receives inline image/PDF data and text parts. The most recent 12 eligible preceding messages supply conversation context, with no carryover between conversations.

Two small live checks, one on Gemma 4 31B Free and one on Gemma 4 26B Free, returned upstream HTTP 429 on 16 October 2026. No automatic POST retries or provider-switching loop was added. Rate limits now have a specific inline message and explicit retry. Live model availability remains an external dependency.

## Visual changes

The composer uses the full mobile content width with a 16 dp outer margin. Duplicate horizontal padding was removed. Home card width, title size, spacing, background colors, outline icon strokes, rounded corners, and the disabled send appearance were compared with native screenshots. Inter is bundled for Android; iOS uses its platform font. Icon controls retain 48 dp touch areas. A 320 dp layout with larger text is covered by the composer behavior test.

The model/credit header, dynamic remote suggestion artwork, and proprietary service functionality are deliberate remaining differences from Manus. The result is not claimed to be an identical copy of every Manus screen.

## Checks and builds

Run flutter analyze and flutter test. Build the native Android app with:

```sh
flutter build apk --release --dart-define-from-file=.local-secrets.json
```

Release signing reads ignored android/key.properties, with storeFile, storePassword, keyAlias, and keyPassword entries. Keep the private keystore outside version control. The local secrets file contains CHAT_PROVIDER and the corresponding GEMINI_API_KEY or OPENROUTER_API_KEY. Use CHAT_PROVIDER=mock explicitly for deterministic UI work. No key is committed.

The release APK was installed on Android and the native picture-selection round trip, connector navigation, permission prompt, active microphone session, and cancellation were checked. The new iOS simulator build also compiled and launched. Physical Android and iPhone checks remain outstanding because no physical phone is connected.

Inter is distributed under the SIL Open Font License. Outline icons are from Lucide under its license; connector brand silhouettes are from Simple Icons under CC0. License files are included with the assets. The custom Outlook and Workspace icons are vector approximations.
