# Current Status — حسابگر من

## Verified baseline
- Target repository: `majidbusy09-blip/hesabgar_man` (immutable GitHub repository ID: `1423683236`).
- Default branch: `main`.
- Current documentation/CI baseline: `3e215d93dffc87ec3d759dc557a179d7fb1fc873`.
- App version in `pubspec.yaml`: `1.0.9+10` (unchanged).
- Package: `hesabgar_man`.
- The dedicated validation workflow pins Flutter `3.27.4`; Dart version is supplied by that Flutter toolchain.

## Repository structure
- Application source: `lib/`.
- Automated tests: `test/`.
- Build workflow: `.github/workflows/build.yml`.
- Dedicated validation workflow: `.github/workflows/project-validation.yml`.
- Ordinary builds may produce APK/AAB workflow artifacts. GitHub Release publication is now a separate, manual-only job on `main`, requiring `workflow_dispatch` with `publish_release=true`. Ordinary pushes and PR validation do not publish a release.

## Test inventory
- Calculator logic tests.
- Accounting logic tests.
- Calendar recurrence and storage tests.
- Category and expense model tests.
- Finance logic tests.
- Check model and finance tests.
- Report logic tests.
- A placeholder widget test remains; it is not evidence of broad widget-level coverage.

## CI status
- Exact PR head `41476246df42bf7c4147fc79b1d4a656ad6eeeb5` passed validation in workflow run `45599635131` (run #16).
- Successful steps included Flutter setup, release-workflow YAML parsing, dependency resolution, lockfile artifact upload, static analysis, pinned font asset retrieval, and Flutter tests.
- The run uploaded `hesabgar-pubspec-lock` as artifact `15014847590` (retention through 2026-12-02). This is a review artifact, not a committed lockfile.
- A committed `pubspec.lock` is still absent from `main`; reproducible dependency resolution is therefore not yet fully pinned in the repository.

## Operational status and remaining acceptance
- No app version increment, signing change, store upload, production change, or release publication was performed as part of this CI hardening.
- The release gate PR was merged as commit `3e215d93dffc87ec3d759dc557a179d7fb1fc873`.
- CI analysis/tests do not replace manual installation and device acceptance by the owner.
- Project onboarding remains `registered`; central readiness gates, source-index compatibility, namespace isolation review, and manual device acceptance are not complete.
