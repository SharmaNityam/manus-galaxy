# Performance observation

| Field | Observation |
| --- | --- |
| Metric | Local conversation hydration duration |
| Device | Pixel 9 Pro API 35 Android emulator |
| Build | Release APK, ARM64 |
| Dataset | One conversation with two messages |
| Backend | Deterministic mock for chat; Hive local store for history and messages |
| Method | Force-stop the app, relaunch it, reopen the saved conversation from history, and read the `performance.local_hydration` log entry |
| Result | 1,405 microseconds for the recorded cold-process reopen |

This measures one small transcript on an emulator. It is a reproducible observation, not a device-independent latency target or a physical-phone benchmark. The measured path reads the local database and does not make a network request.

Reproduce it with:

```sh
adb logcat -c
adb shell am force-stop com.galaxyai.manusgalaxy
adb shell monkey -p com.galaxyai.manusgalaxy 1
```

Open the saved conversation from the history drawer, then inspect:

```sh
adb logcat -d | grep performance.local_hydration
```
