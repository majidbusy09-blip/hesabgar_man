# Current Status — حسابگر من

## Verified baseline
- Target repository: `majidbusy09-blip/hesabgar_man` (immutable GitHub repository ID: `1423683236`).
- Default branch: `main`.
- Current verified main baseline: `f3fb9f0e5befdb9240f5eac1234b4487302b4a30`.
- App version in `pubspec.yaml`: `1.0.9+10` (unchanged).
- Package: `hesabgar_man`.
- The dedicated validation workflow pins Flutter `3.27.4`; Dart version is supplied by that Flutter toolchain.

## Repository structure
- Application source: `lib/`.
- Automated tests: `test/`.
- Build workflow: `.github/workflows/build.yml`.
- Dedicated validation workflow: `.github/workflows/project-validation.yml`.
- Ordinary builds may produce APK/AAB workflow artifacts. GitHub Release publication is a separate, manual-only job on `main`, requiring `workflow_dispatch` with `publish_release=true`. Ordinary pushes and PR validation do not publish a release.

## Test inventory
- Calculator logic tests.
- Accounting logic tests.
- Calendar recurrence and storage tests.
- Category and expense model tests.
- Finance logic tests.
- Check model and finance tests.
- Report logic tests.
- A placeholder widget test remains; it is not evidence of broad widget-level coverage.

## CI and source-index verification
- Release-safety gate PR #3 passed exact-head validation run `45599635131` and merged as `3e215d93dffc87ec3d759dc557a179d7fb1fc873`.
- Documentation and CI path-filter PR #4 passed run `45607356065` and merged.
- Project-bound resolved-index smoke-test PR #5 passed run `45608067689` and merged.
- Task-intelligence smoke-test PR #6 passed run `45608976561` and merged as `f3fb9f0e5befdb9240f5eac1234b4487302b4a30`.
- Run #25 validated the actual Hesabgar checkout against the immutable repository ID and pinned source SHA, generated the project-bound resolved index and curated application-startup critical-path report, and exercised the central context selector and impact analyzer against `lib/main.dart`.
- The generated source index covered 6 Dart files. The earlier exact artifact recorded 1,637 declarations, 9,205 call sites, 9,094 resolved calls, 111 unresolved calls, 1,524 internal edges, and zero analyzer errors.
- Project-bound index artifacts are CI outputs only; generated JSON is not committed into application source.
- `pubspec.lock` is still absent from `main`. CI artifact `15018193165` contains the verified lockfile; its SHA-256 is `5e758df74d809f0b11c56f834364456d16d7d1bf48534312bc08dd84fa542cac`. It is a review artifact, not yet committed.

## Operational status and remaining acceptance
- No app version increment, signing change, store upload, production change, or release publication was performed.
- Project onboarding remains `registered`; central `source_index.strategy` remains `none`.
- Source-index compatibility and initial task-intelligence consumption are verified, but this does not activate project execution.
- Remaining gates: commit the exact lockfile, complete TOCTOU/output-path review, verify a real project-bound cache consumer/backend, and perform manual installation/device acceptance.
