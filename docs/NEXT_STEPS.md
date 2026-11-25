# Next Steps — حسابگر من

## Priority 1 — reproducible baseline and onboarding
1. Review the generated `pubspec.lock` artifact from successful pinned CI run `45599635131`, then commit the exact reviewed lockfile without changing `pubspec.yaml` or app version.
2. Verify the generic Dart resolved-index CLI against this exact repository checkout, immutable repository ID `1423683236`, manifest digest, and full source SHA before enabling any source-index strategy.
3. Complete an independent adversarial review of project namespace path handling, including symlink races/TOCTOU and output-file handling.
4. Keep the central project lifecycle at `registered` until all readiness gates pass.
5. Perform manual Android installation/smoke testing after CI and documentation review.

## Priority 2 — calculator correctness
1. Add focused regression coverage for inverse-trigonometric functions and DEG/RAD round trips, including `sin(asin(0.5))`.
2. Verify parsing, display rounding and internal numeric precision remain separate.
3. Keep accounting-mode behavior covered independently from the scientific calculator.

## Priority 3 — checks and finance tools
1. Continue the professional «چک‌های من» workflow with check date as the primary date and issue date optional.
2. Keep branch/account fields out unless a later product decision explicitly adds them.
3. Preserve clear status transitions such as passed/settled and returned.
4. Verify local reminders, notification routing and stable notification IDs across app restarts.
5. Preserve local-first storage and test migrations/backward compatibility.

## Priority 4 — maintainability
1. Gradually extract calculator and finance logic from the large `features.dart` module when changes justify it.
2. Expand meaningful widget tests beyond the existing placeholder.
3. Keep the Persian-first RTL experience and existing data intact.
4. Do not increment the app version or create a release unless explicitly requested by the owner.

## Owner-side acceptance
The owner should manually test installation, calculator modes, finance calculations, check reminders/notifications, calendar navigation and data persistence on an Android device. A CI pass alone is not device acceptance.
