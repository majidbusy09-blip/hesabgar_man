# Next Steps — حسابگر من

## Priority 1 — reproducible baseline and project isolation
1. Commit the exact verified `pubspec.lock` from the pinned Flutter 3.27.4 CI artifact; SHA-256: `5e758df74d809f0b11c56f834364456d16d7d1bf48534312bc08dd84fa542cac`. Do not change `pubspec.yaml` or app version.
2. Complete an independent adversarial review of output-path TOCTOU and symlink races. The current source-indexer rejects static symlink traversal, but this is not a complete race-free filesystem guarantee.
3. Identify or implement a real project-bound cache backend/consumer. Existing namespace helpers and unit tests prove key/path separation by project and source revision, but helper APIs alone do not establish runtime cache isolation.
4. Keep the central project lifecycle at `registered` and `source_index.strategy=none` until lockfile, cache isolation and security gates are complete.
5. Perform manual Android installation and device acceptance.

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
