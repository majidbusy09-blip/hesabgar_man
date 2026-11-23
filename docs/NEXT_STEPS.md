# حسابگر من — Prioritized Next Steps

1. Use the new read-only PR workflow as the required regression gate: active-source analysis plus the ten focused test files. Resolve failures before considering app changes ready for review.
2. Confirm current app version and release state before any version or publishing change; source currently says `1.0.9+10`.
3. For check/reminder changes, trace `checks.dart`, `calendar_v2.dart`, and `notifications.dart`; verify persistence, status transitions, scheduling, cancellation, and rescheduling.
4. Review local-storage migration and backup/export strategy before changing persisted models.
5. Keep handoffs mobile-first: short ordered steps and exact test outcomes.
6. Review release workflow separately; it currently triggers on main pushes and includes release-writing permissions. Do not change release behavior without explicit approval.

Deferred: no version bump, signing, package identity, release, or deployment without explicit approval; no broad UI rewrite without a concrete request; do not infer notification/device correctness from unit tests alone.
