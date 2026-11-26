# Next Steps — حسابگر من

## Priority 1 — finish multi-project onboarding gates
1. Central PRs #138/#141/#142/#144 and target PRs #22/#28 are merged. The corrected pinned caller passed its live read-only retest, but central dispatch remains skipped because the secrets are absent. Configure the narrowly scoped token secrets, rerun a live Issue test, and confirm the central `task-inbox` branch contains exactly one record; repeat the event to prove idempotence. Keep Hesabgar registered; no lease or implementation dispatch.
2. Complete the central orchestrator integration so project-bound semantic indexes are generated or retrieved automatically for a pinned project/revision, then freshness- and identity-verified before use.
3. Namespace/cache isolation across the actual JET VPN and Hesabgar manifests is covered by central PR #128. Complete the stronger end-to-end test across two checked-out repositories, including task records, context cache, indexes, impact reports, branch/lease identifiers, and distinct toolchain execution.
4. Complete automatic source-index artifact provisioning/retrieval and freshness checks for a pinned project revision. Do not change Hesabgar `source_index.strategy=none` until this works at runtime.
5. Complete the reusable cross-repository lease/handoff path with separate target-repository and trusted-control-plane checkouts; keep registered projects blocked from lease claims and implementation.
6. Keep the Hesabgar manifest at `lifecycle=registered` until runtime provisioning, end-to-end isolation, and all onboarding gates are independently verified.
7. Complete manual Android installation and device acceptance. Record device model, Android version, build identifier, and actual pass/fail observations.
8. Keep app version `1.0.9+10`; do not modify signing, publish a GitHub Release, or upload to a store without separate explicit owner authorization.

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
Manually test installation, calculator modes, finance calculations, check reminders/notifications, calendar navigation, and data persistence on an Android device. CI passes and generated APK/AAB artifacts do not substitute for device acceptance.
