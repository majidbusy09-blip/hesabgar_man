# حسابگر من — Project Context

## Verified snapshot
- Repository: `majidbusy09-blip/hesabgar_man`
- Inspected `main` SHA: `47d5810fa02de991ed34f6a15d1409f686928eee`
- `pubspec.yaml` currently says `1.0.9+10`. Older chat notes said `1.0.7+8`; that note is stale relative to this source snapshot. This docs task does not change or endorse a version bump.
- 81 tracked files; 10 focused test files under `test/`.

## Architecture map
- `lib/main.dart` (85 lines): app bootstrap, notification payload routing, root app.
- `lib/core.dart`: local storage, theme/colors, formatting, feedback, providers.
- `lib/features.dart`: calculator engine/UI, unit and compound conversion, finance screens.
- `lib/checks.dart`: bank-check models/status history, persistence, reminders/calendar synchronization, forms and screens.
- `lib/calendar_v2.dart`: calendar event/note/task/personal-occasion models, store, calendar UI, date tools.
- `lib/notifications.dart`: initialization, permissions, notification scheduling and cancellation, loan/event reminders.
- `assets/`: branding, bank imagery, sounds. `tool/patch_signing.py`: CI signing helper.

## Cross-module invariants
- Check reminders and calendar links span `checks.dart`, `calendar_v2.dart`, and `notifications.dart`; inspect all three before changing this behavior.
- Finance and calculator code share formatting/numeric utilities; check `core.dart` and `features.dart` before changing shared behavior.
- Verify exact storage keys and migrations in source before altering persisted models. README's local-storage summary is not a complete data-flow audit.

## CI and runtime
- Workflow triggers on pushes to `main`, has `contents: write`, runs Flutter analysis/tests, builds release APK/AAB, and includes a GitHub Release step.
- Unit tests do not prove Android alarm delivery, reboot behavior, exact-alarm permission handling, or device-specific behavior.
- This documentation baseline does not modify source, version, signing, or workflow.
