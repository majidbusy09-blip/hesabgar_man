# Next Steps — حسابگر من

## Priority 1 — complete onboarding acceptance
1. Confirm post-merge Project Validation run `45642260366` succeeds on main commit `eb121f6db859da4eac495cb2d7d0b5f4e95355b1`.
2. Confirm post-merge APK/AAB build run `45642260517` succeeds. This is an artifact build, not authorization to publish a GitHub Release.
3. Independently review the project-bound Dart source-index CLI and decide whether to adopt a supported adapter. Keep central manifest `lifecycle=registered` and `source_index.strategy=none` until that decision is reviewed; do not infer activation from smoke-test success.
4. Complete manual Android installation and device acceptance. Record actual results; CI cannot replace this owner-side gate.
5. Keep app version `1.0.9+10`; do not modify signing, publish a Release, or upload to a store without explicit owner authorization.

## Priority 2 — calculator correctness
1. Add focused regression coverage for inverse-trigonometric functions and DEG/RAD round trips, including `sin(asin(0.5))`.
2. Verify parsing, display rounding, and internal numeric precision remain separate.
3. Keep accounting-mode behavior covered independently from the scientific calculator.

## Priority 3 — checks and finance tools
1. Continue the professional «چک‌های من» workflow with check date as the primary date and issue date optional.
2. Keep branch/account fields out unless a later product decision explicitly adds them.
3. Preserve clear status transitions such as passed/settled and returned.
4. Verify local reminders, notification routing, and stable notification IDs across app restarts.
5. Preserve local-first storage and test migrations/backward compatibility.

## Priority 4 — maintainability
1. Gradually extract calculator and finance logic from the large `features.dart` module when changes justify it.
2. Expand meaningful widget tests beyond the existing placeholder.
3. Keep the Persian-first RTL experience and existing data intact.
4. Preserve the current version unless the owner explicitly requests a version change.

## Owner-side acceptance
Manually test installation, calculator modes, finance calculations, check reminders/notifications, calendar navigation, and data persistence on an Android device. Record device model, Android version, app build identifier, and pass/fail observations. A CI pass alone is not device acceptance.
