# Current Status — حسابگر من

## Verified baseline
- Target repository: `majidbusy09-blip/hesabgar_man` (immutable GitHub repository ID: `1423683236`).
- Default branch: `main`.
- Current main commit: `a8f8ca8edaab67217e0779c0579a1a703f07ac32` (PR #16 documentation reconciliation; PR #17 records live intake smoke evidence).
- Current application-source baseline: `9b5b324e197d806afa7365abe360c972dbeaf13a` (PRs #13–#16 and intake workflow changes did not modify application source).
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
- Latest post-merge build run [`45677317842`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45677317842) succeeded on main SHA `a8f8ca8edaab67217e0779c0579a1a703f07ac32`. Artifacts (unexpired): APK 31,256,257 bytes, digest `sha256:291cab4e9f1a703f5f942da0c420b3eafe409a82d0aa5219ec99994e93541bbc`; AAB 64,207,679 bytes, digest `sha256:102af867f1f118ba0074bcb43b1b74fc3c20ebc238dddce70dad1e87cdeb1c22`. These are workflow artifacts, not a published GitHub Release.
- Earlier index statistics (6 Dart files, 1,637 declarations, 9,205 call sites, 9,094 resolved calls, 111 unresolved calls, 1,524 internal edges, zero analyzer errors) belong to an earlier pinned source revision and must not be presented as current measurements.

## Latest target-side verification after intake workflow merge
- Target PR #15 merged as `7b008f8c5fb493db40ba04ad0d3c556176085471`; the project validation run [`45675484236`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45675484236) passed on that exact SHA.
- Post-merge APK/AAB build [`45675484248`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45675484248) also passed. The latest APK and AAB digests are recorded above.
- The reusable issue-intake workflow is configured in the target repository and calls the central reusable workflow at pinned workflow commit `7b2d7dab0d374eed2d0d6745546f4bc2f6e266a0`.
- A live temporary Issue #17 smoke test succeeded in run [`45677327585`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45677327585). The workflow uploaded `agent-task-17` (artifact ID `15052647029`, 986 bytes, digest `sha256:684fcf539601637432ee08e861dc929ed989757ab1a47ddbab1cbe9f78471481`). The artifact records `execution.status=validated-awaiting-activation`, `implementation_eligible=false`, `lease_claimed=false`, `agent_dispatched=false`, `model_called=false`, and `source_uploaded=false`. The issue is closed. No lease, model call, source upload, branch, PR, or implementation was created.
- The central Hesabgar manifest now protects `.github/workflows/agent-task-intake.yml`. Its digest changed when that protected path was added; new v2 task payloads must use the current central manifest digest.
- The workflow's only permissions are `contents: read` and `issues: read`. It can produce a `validated-awaiting-activation` intake artifact; it cannot claim a lease or authorize implementation.

## Read-only cross-repository task intake
- Central reusable workflow PR #130 merged as `7b2d7dab0d374eed2d0d6745546f4bc2f6e266a0`. It supports a target repository calling trusted central intake tooling while preserving the target repository as the event/source context.
- Target PR #15 merged the caller workflow with only `contents: read` and `issues: read` permissions. The live smoke test confirms the caller and central reusable workflow work together.
- A registered project may receive a validated task artifact with status `validated-awaiting-activation`; this is an inbox record only. It does not claim a lease, start an agent, call a model, or upload source.
- Lease claims and implementation handoffs still require `lifecycle=active`; Hesabgar remains registered and is not implementation-enabled.

## JET AI onboarding and remaining acceptance
- Central project manifest remains `lifecycle=registered`; `source_index.strategy=none` is intentionally unchanged.
- CI now proves project-bound generation and Task Intelligence consumption for the Hesabgar checkout. This does **not** yet prove that the central orchestrator automatically provisions or retrieves fresh artifacts during every runtime task.
- Project-scoped context cache is wired into task preparation; tests cover namespace separation, source/input drift, corruption rejection, and cache-hit/rebuild behavior. Handoff revalidation rebuilds context from the pinned Git tree rather than trusting the cache.
- Central namespace and file-I/O hardening passed exact-head validation.
- Remaining gates: automatic runtime index provisioning/retrieval with freshness enforcement; end-to-end two-repository checkout/lease/handoff isolation and differing toolchain verification (namespace/cache isolation is already covered by central PR #128); and manual Android installation/device acceptance by the owner. CI success is not device acceptance.
- Keep version `1.0.9+10`; do not publish a Release, change signing, or upload to a store without a separate explicit decision.
