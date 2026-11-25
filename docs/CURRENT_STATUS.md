# Current Status — حسابگر من

## Verified baseline
- Target repository: `majidbusy09-blip/hesabgar_man` (immutable GitHub repository ID: `1423683236`).
- Default branch: `main`.
- Current main commit at this PR's base: `670161b0e934badd3027ec8e53b719ff0d309242` (PR #14 documentation-only merge).
- Current application-source baseline: `9b5b324e197d806afa7365abe360c972dbeaf13a` (PR #12; PR #13 changed documentation only).
- App version in `pubspec.yaml`: `1.0.9+10` (unchanged).
- Package: `hesabgar_man`.
- Dedicated validation workflow pins Flutter `3.27.4`; Dart `3.6.2` is bundled with that toolchain.
- Reviewed `pubspec.lock` is committed. Its SHA-256 is `5e758df74d809f0b11c56f834364456d16d7d1bf48534312bc08dd84fa542cac`.

## Repository structure and release safety
- Application source: `lib/`; automated tests: `test/`.
- Build workflow: `.github/workflows/build.yml`.
- Dedicated validation workflow: `.github/workflows/project-validation.yml`.
- Ordinary builds may produce APK/AAB workflow artifacts. GitHub Release publication is a separate manual-only job on `main`, requiring `workflow_dispatch` with `publish_release=true`.
- No app version increment, signing change, store upload, production change, or GitHub Release publication was performed.

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
- PR #10 committed the CI-resolved dependency lockfile.
- PR #11 reconciled project documentation.
- PR #12 strengthened project-bound source-index freshness and identity checks and was merged as `9b5b324e197d806afa7365abe360c972dbeaf13a`.
- Post-merge Project Validation run [`45665085754`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45665085754) succeeded on the current main SHA. It generated the project-bound resolved index and critical-path report, verified exact source/repository/project bindings and tracked-file fingerprints, smoke-tested central Task Intelligence against the real artifacts, and passed static analysis and Flutter tests.
- Post-merge APK/AAB build run [`45665085751`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45665085751) succeeded on the same SHA.
- Available, unexpired workflow artifacts:
  - APK: 31,256,270 bytes; SHA-256 `65578700d44e2bfaf4b31ac7458105b9690b2904d90d857a0ceca2aa1da37b73`.
  - AAB: 64,207,679 bytes; SHA-256 `a41443b46c2770019d42cd526250c9efce2e22a6cd86ca5d3e3ebe1c75953ed5`.
- The manual GitHub Release job was skipped; these are CI artifacts, not a published release.
- Documentation reconciliation PR #13 merged as `423e45439fd6dbe0744c93eefc336161f16ed119`, followed by documentation-only PR #14; neither changed application source.
- Post-merge Project Validation run [`45670351627`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45670351627) and APK/AAB build run [`45670351687`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45670351687) both succeeded on the exact PR #14 main commit.
- Latest build artifacts from run `45670351687` (unexpired): APK 31,256,266 bytes, artifact digest `sha256:84a806e02ae748acbf2fcd2316e74bdebdfbedc3a0c23e03bbb7867c7a592b70`; AAB 64,207,679 bytes, artifact digest `sha256:8743c9d465a34082f56dc59d1fd478c4ea4c0aa160bdb6c0e0538fe7293eb7f7`. The rebuild is still a workflow artifact, not a published GitHub Release.
- Earlier index statistics (6 Dart files, 1,637 declarations, 9,205 call sites, 9,094 resolved calls, 111 unresolved calls, 1,524 internal edges, zero analyzer errors) belong to an earlier pinned source revision and must not be presented as current measurements.

## Read-only cross-repository task intake
- Central reusable workflow PR #130 merged as `7b2d7dab0d374eed2d0d6745546f4bc2f6e266a0`. It supports a target repository calling trusted central intake tooling while preserving the target repository as the event/source context.
- The target-side caller workflow is being added in this change. It has only `contents: read` and `issues: read` permissions.
- A registered project may receive a validated task artifact with status `validated-awaiting-activation`; this is an inbox record only. It does not claim a lease, start an agent, call a model, or upload source.
- Lease claims and implementation handoffs still require `lifecycle=active`; Hesabgar remains registered and is not implementation-enabled.

## JET AI onboarding and remaining acceptance
- Central project manifest remains `lifecycle=registered`; `source_index.strategy=none` is intentionally unchanged.
- CI now proves project-bound generation and Task Intelligence consumption for the Hesabgar checkout. This does **not** yet prove that the central orchestrator automatically provisions or retrieves fresh artifacts during every runtime task.
- Project-scoped context cache is wired into task preparation; tests cover namespace separation, source/input drift, corruption rejection, and cache-hit/rebuild behavior. Handoff revalidation rebuilds context from the pinned Git tree rather than trusting the cache.
- Central namespace and file-I/O hardening passed exact-head validation.
- Remaining gates: automatic runtime index provisioning/retrieval with freshness enforcement; end-to-end two-repository checkout/lease/handoff isolation and differing toolchain verification (namespace/cache isolation is already covered by central PR #128); and manual Android installation/device acceptance by the owner. CI success is not device acceptance.
- Keep version `1.0.9+10`; do not publish a Release, change signing, or upload to a store without a separate explicit decision.
