# حسابگر من — Agent Instructions

## Project identity
- Repository: `majidbusy09-blip/hesabgar_man`
- Immutable GitHub repository ID: `1423683236`
- Default branch: `main`
- Project type: Flutter Android application; primary language Dart.
- Current version at onboarding baseline: `1.0.9+10`.

## Working rules
1. Read `docs/PROJECT_CONTEXT.md`, `docs/CURRENT_STATUS.md`, and `docs/NEXT_STEPS.md` before changing application code.
2. Preserve the existing Persian-first user experience and right-to-left layout unless a task explicitly requires otherwise.
3. Keep changes focused. Avoid broad rewrites of the existing feature modules without a specific requirement and regression coverage.
4. Do not change the app version, Android application ID, signing configuration, release workflow, or store metadata unless the owner explicitly requests it.
5. Never add secrets, API keys, signing keys, passwords, tokens, private user data, or production credentials to source control, manifests, logs, or generated reports.
6. Treat `android/key.properties`, `android/app/key.properties`, signing material, and repository secrets as protected. Do not read, print, modify, or upload their contents.
7. Prefer local-first storage for personal finance data. Any change to data storage, backup, export, or network transmission requires explicit scope and privacy review.
8. Add or update focused tests for logic changes. Run the fixed Flutter analysis and test checks before proposing a merge.
9. A green CI run does not replace manual Android-device validation. The project owner performs on-device acceptance.
10. Do not publish releases, upload APK/AAB files to stores, deploy, or alter production settings without separate human approval.

## Owner workflow and communication
- The owner primarily works from an Android phone using GitHub and browser-based tools. Keep instructions mobile-friendly and provide exact repository paths and GitHub links where useful.
- Explain what changed, why it changed, what was tested, and what still requires owner-side device testing.
- The app is Persian-first; preserve existing terminology and visual conventions. Do not introduce English UI strings without an explicit product requirement.

## Verification
- Static analysis: `flutter analyze lib test --no-pub --no-fatal-infos --no-fatal-warnings`
- Tests: `flutter test --no-pub`
- CI uses the pinned Flutter toolchain defined in `.github/workflows/project-validation.yml`.
- Report skipped checks as skipped, never as passed.
