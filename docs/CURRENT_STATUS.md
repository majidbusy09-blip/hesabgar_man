# Current Status — حسابگر من

## Verified baseline
- Target repository: `majidbusy09-blip/hesabgar_man` (immutable GitHub repository ID: `1423683236`).
- Default branch: `main`.
- Current main commit: `bbc6bacee860a0ed4b8b519b00d5746d27fb9525` (PR #23 records central inbox transport and target dispatch state; documentation only).
- Current application-source baseline: `9b5b324e197d806afa7365abe360c972dbeaf13a` (PR #12; subsequent PRs #13–#18 changed documentation or CI/workflow configuration only).
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
- Latest build on the pre-deduplication main checkpoint: run [`45677317842`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45677317842) succeeded on SHA `a8f8ca8edaab67217e0779c0579a1a703f07ac32`. Unexpired artifacts: APK 31,256,257 bytes, digest `sha256:291cab4e9f1a703f5f942da0c420b3eafe409a82d0aa5219ec99994e93541bbc`; AAB 64,207,679 bytes, digest `sha256:102af867f1f118ba0074bcb43b1b74fc3c20ebc238dddce70dad1e87cdeb1c22`. The post-PR #18 build on main SHA `530daceeaea180c9d2e4a3d333e3981a3dddbaad` is tracked separately below.
- Earlier index statistics (6 Dart files, 1,637 declarations, 9,205 call sites, 9,094 resolved calls, 111 unresolved calls, 1,524 internal edges, zero analyzer errors) belong to an earlier pinned source revision and must not be presented as current measurements.

## Latest target-side verification after intake workflow merge
- Target PR #15 merged as `7b008f8c5fb493db40ba04ad0d3c556176085471`; the project validation run [`45675484236`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45675484236) passed on that exact SHA.
- Post-merge APK/AAB build [`45675484248`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45675484248) also passed. The latest APK and AAB digests are recorded above.
- The reusable issue-intake workflow is configured in the target repository and calls the central reusable workflow at a pinned workflow commit. Its live Issue-triggered execution has now been verified; the registered-project read-only result and caller contract passed.
- The central Hesabgar manifest now protects `.github/workflows/agent-task-intake.yml`. Its digest changed when that protected path was added; new v2 task payloads must use the current central manifest digest.
- The workflow's only permissions are `contents: read` and `issues: read`. A live Issue event produced a `validated-awaiting-activation` artifact; it did not claim a lease, invoke a model, dispatch an agent, or upload source.

## Read-only cross-repository task intake
- Central reusable workflow PR #130 merged as `7b2d7dab0d374eed2d0d6745546f4bc2f6e266a0`. It supports a target repository calling trusted central intake tooling while preserving the target repository as the event/source context.
- The target-side caller workflow is merged and has only `contents: read` and `issues: read` permissions. Target PR #18 also added `.github/workflows/agent-task-intake.yml` to the project-validation path filters.
- A registered project may receive a validated task artifact with status `validated-awaiting-activation`; this is an inbox record only. It does not claim a lease, start an agent, call a model, or upload source.
- Lease claims and implementation handoffs still require `lifecycle=active`; Hesabgar remains registered and is not implementation-enabled.

## JET AI onboarding and remaining acceptance
- Central project manifest remains `lifecycle=registered`; `source_index.strategy=none` is intentionally unchanged.
- CI now proves project-bound generation and Task Intelligence consumption for the Hesabgar checkout. This does **not** yet prove that the central orchestrator automatically provisions or retrieves fresh artifacts during every runtime task.
- Project-scoped context cache is wired into task preparation; tests cover namespace separation, source/input drift, corruption rejection, and cache-hit/rebuild behavior. Handoff revalidation rebuilds context from the pinned Git tree rather than trusting the cache.
- Central namespace and file-I/O hardening passed exact-head validation.
- Remaining gates: automatic runtime index provisioning/retrieval with freshness enforcement; automatic, idempotent ingestion of target intake artifacts into a durable central task record/queue; end-to-end two-repository checkout/lease/handoff isolation and differing toolchain verification (namespace/cache isolation is already covered by central PR #128); and manual Android installation/device acceptance by the owner. CI success is not device acceptance.
- Keep version `1.0.9+10`; do not publish a Release, change signing, or upload to a store without a separate explicit decision.


## Live Issue intake evidence and duplicate-event hardening
- Temporary Hesabgar Issue #17 exercised the actual cross-repository reusable workflow. Run [`45677327585`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45677327585) validated task `live-intake-smoke-20261125` and uploaded artifact `agent-task-17` (986 bytes, artifact ID `15052647029`, SHA-256 `684fcf539601637432ee08e861dc929ed989757ab1a47ddbab1cbe9f78471481`). The registered-project result is `validated-awaiting-activation` and not implementation-eligible; the workflow log explicitly confirms no lease was claimed and no model or implementation agent was invoked.
- The first attempt's two runs on `opened` and `labeled` failed closed because the test payload had an incorrect manifest digest. The canonical SHA-256 binding was corrected; the workflow accepted the task only after exact manifest/repository binding validation.
- Central PR #132 merged as `eb2ade7c18e5af3bafc67f7ee73613465d110e6d`, improving mismatch diagnostics and adding a regression fixture for the exact Hesabgar payload. Central PR #134 merged as `cd6c0f2f70927f67d11bdf00c3a84fcf187d4bab`, removing the duplicate `opened` trigger from the central first-party workflow.
- Target PR #18 merged as `530daceeaea180c9d2e4a3d333e3981a3dddbaad`, changed the target intake trigger to `labeled` and `edited`, and added its workflow path to the project-validation filters. Exact-head PR validation run [`45678323306`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45678323306) succeeded.
- A second live test of Issue #17 after PR #18 produced exactly one intake run [`45678817592`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45678817592), succeeded, and uploaded artifact `agent-task-17` (1,005 bytes, SHA-256 `99734bab30303c3b3c1c9a19c3481a9bd18d180228baddc0111f19196ac524c4`, artifact ID `15053470675`). The temporary Issue was closed again.
- Post-PR #18 Project Validation run [`45678762925`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45678762925) succeeded on main. Post-PR #18 APK/AAB build run [`45678762986`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45678762986) completed successfully. APK: 31,256,262 bytes, SHA-256 `a674589e10a9c1f740a0c73ab605f6a45f2adb6fa57a288bea37406211c2a5af`; AAB: 64,207,679 bytes, SHA-256 `fcba275bdb9d53f01e60c540996bb7951c189d4c09a523e259caf283b00c8859`. Both artifacts are unexpired CI artifacts, not published Releases.
- Central PR #138 merged the durable idempotent inbox importer. Central PR #141 merged the transport workflow: it validates the dispatch, artifact, immutable repository identity, source run/SHA, and re-fetches the live Issue to confirm it remains open, labeled, and body-identical before persisting to the `task-inbox` branch. Central PR #142 merged as `a67ce545db259a94bc4ec243d4ec2858dbb80455`; it serializes by repository ID + Issue number and retries concurrent inbox-branch pushes. Target PR #22 merged as `4195c58176bab1d0eab2d614d0125913c5e30f09`; it passes `secrets: inherit` and pins the reusable workflow to the reviewed central commit. Exact-head PR validation [`45685677330`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45685677330) and post-merge main validation [`45686596443`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45686596443) succeeded. A new live retest on the pinned reusable workflow succeeded at run [`45687022313`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45687022313), uploading artifact `agent-task-17` (1,005 bytes, SHA-256 `a59c8a2eb941a112255666e1b8b7c3582a82bc764688088eec372f46dd22d0e2`, artifact ID `15056447830`). The optional central dispatch step was skipped and the expected warning emitted because `JET_AI_CENTRAL_DISPATCH_TOKEN` is not configured; no central queue record was created. Temporary Issue #17 was closed again. Post-merge APK/AAB build [`45686596413`](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45686596413) succeeded. APK: 31,256,270 bytes, SHA-256 `fff124b700a5ebb2a8b5bb45f41b6fa79e837f6bf0a88a556bea9d6983e32b27`; AAB: 64,207,679 bytes, SHA-256 `ea82e2b2326209acba619ec71212b6801abd15b10ffeade919ef5cac8620a42e`. Both are unexpired CI artifacts, not Releases. Automatic dispatch requires the two narrowly scoped Actions secrets. The project remains `registered`, `source_index.strategy=none`, app version `1.0.9+10`; no lease, model call, implementation dispatch, app source change, or release occurred.
