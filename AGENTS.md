# Agent instructions — حسابگر من

1. Read `docs/PROJECT_CONTEXT.md`, `docs/CURRENT_STATUS.md`, and `docs/NEXT_STEPS.md` before engineering work.
2. Re-fetch current source, branch/SHA, tests, and workflow before changes; docs are navigation aids, not substitutes for verification.
3. Work on a dedicated branch; never commit directly to `main`.
4. Preserve local-storage formats, calculation semantics, Jalali date behavior, notification IDs/scheduling, and user data unless a scoped migration is requested.
5. Add/update focused regression tests for logic changes. Separate unit-test evidence from Android alarm/device behavior.
6. Record meaningful changes and exact verification in docs and PRs.

## Safety
- Current workflow triggers on pushes to `main`, has `contents: write`, builds release APK/AAB outputs, and contains a GitHub Release step. Treat main changes as release-sensitive.
- Do not dispatch releases, create tags, alter signing/package identity, or publish without explicit approval.
- Do not change the app version unless explicitly requested and approved.
- Never expose secrets, keystores, passwords, or private user data.

## Architecture
- Flutter app split across `main.dart`, `core.dart`, `features.dart`, `checks.dart`, `calendar_v2.dart`, and `notifications.dart`.
- Preserve the existing focused tests and trace cross-module behavior before modifying reminders, finance, or persisted models.
