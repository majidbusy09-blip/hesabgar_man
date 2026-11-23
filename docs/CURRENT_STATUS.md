# حسابگر من — Current Status

- Snapshot: 2026-11-23; inspected `main` SHA `47d5810fa02de991ed34f6a15d1409f686928eee`.
- Version in current `pubspec.yaml`: `1.0.9+10`, not older chat-recorded `1.0.7+8`.
- Modular source: `main.dart`, `core.dart`, `features.dart`, `checks.dart`, `calendar_v2.dart`, `notifications.dart`.
- Ten focused test files are tracked; workflow runs analysis and a selected test set.
- Workflow triggers on pushes to `main`, has contents write permission, builds release APK/AAB, and contains a GitHub Release step.
- No source, version, signing, or workflow changes are included in this documentation baseline.
- No Android device test result is claimed.