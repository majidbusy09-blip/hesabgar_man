# Current Status — حسابگر من

## Baseline
- Snapshot inspected for onboarding: `a07992d3f4721fe1524bd093502f08171dafc92b`.
- App version in `pubspec.yaml`: `1.0.9+10`.
- Package: `hesabgar_man`.
- Flutter/Dart app; declared Dart SDK range is `>=3.0.0 <4.0.0`.
- No app source or version files were changed by this documentation/CI onboarding PR.

## Repository structure
- Application source: `lib/`.
- Automated tests: `test/`.
- Build/release workflow: `.github/workflows/build.yml`.
- Existing build workflow uses Java 17 and Flutter stable, creates Android platform scaffolding in its CI workspace, and can publish release artifacts when triggered on the default branch. Do not use it as a pull-request test runner or trigger a release for validation.

## Test inventory observed
- Calculator logic tests.
- Accounting logic tests.
- Calendar recurrence and storage tests.
- Category and expense model tests.
- Finance logic tests.
- Check model and finance tests.
- Report logic tests.
- A placeholder widget test remains; it is not evidence of full widget-level coverage.

## CI status
- The dedicated pull-request validation workflow is introduced in this onboarding branch and pins Flutter 3.27.4.
- Its first exact-branch result must be recorded here after GitHub Actions completes.
- Dependency resolution currently relies on `flutter pub get`; a committed `pubspec.lock` was not present in the inspected baseline. This remains a reproducibility limitation until a reviewed lockfile is generated and committed.

## Operational status
- No release, store upload, signing change, production change, or app version increment was performed.
- CI analysis/tests do not replace manual installation and device acceptance by the owner.
