# Development Log — حسابگر من

## 2026-11-25 — JET AI onboarding baseline
- Verified repository identity: `majidbusy09-blip/hesabgar_man`, immutable repository ID `1423683236`, default branch `main`.
- Inspected the Flutter/Dart application, package manifest, app entry point, primary feature module, test inventory, and Android build workflow.
- Added project operating instructions, baseline memory documents, and a dedicated Flutter 3.27.4 pull-request validation workflow.
- The validation workflow runs static analysis and tests and does not publish an APK/AAB or access signing secrets.

## 2026-11-25 — exact-main validation before lockfile
- Main commit `8f84499f68aab7a886da4326a353e104f77e705b` passed Project Validation run `45609756813` and build run `45609756943`.
- After documentation PR #8, main commit `cbb94ce66e543b41e82c6e34f35a0875b99a8d77` passed Project Validation run `45617630092` and build run `45617630206`; the manual GitHub Release job was not invoked.
- The verified lockfile was extracted from CI artifact `15020045844`; its SHA-256 was `5e758df74d809f0b11c56f834364456d16d7d1bf48534312bc08dd84fa542cac`.

## 2026-11-25 — verified lockfile committed
- Added the exact CI-verified `pubspec.lock` without changing `pubspec.yaml` or app version.
- PR #10: https://github.com/majidbusy09-blip/hesabgar_man/pull/10
- PR-head commit: `98717764193fc3e46a4d43966b113b49eeebf062`; exact validation run `45638699722` succeeded, including dependency resolution, source-index/critical-path/task-intelligence smoke checks, static analysis, and tests.
- PR #10 merged to main as `eb121f6db859da4eac495cb2d7d0b5f4e95355b1`.
- App version remains `1.0.9+10`; no Release was published.
- Post-merge main validation run `45642260366` and APK/AAB build run `45642260517` were started. Their outcomes must be checked before declaring the post-merge baseline fully green.
- Central project manifest remains `lifecycle=registered` and `source_index.strategy=none`. Manual Android device acceptance and source-index strategy review remain outstanding.


## 2026-11-25 — PR #12 and post-merge verification
- PR #12 strengthened deterministic source-index freshness checks and exact repository/project/source binding checks; merged to main as `9b5b324e197d806afa7365abe360c972dbeaf13a`.
- Post-merge Project Validation run `45665085754` succeeded on that exact SHA, including resolved-index generation, critical-path report generation, Task Intelligence smoke tests against the generated artifacts, static analysis, and Flutter tests.
- Post-merge APK/AAB build run `45665085751` also succeeded on that SHA. APK artifact: 31,256,270 bytes, SHA-256 `65578700d44e2bfaf4b31ac7458105b9690b2904d90d857a0ceca2aa1da37b73`. AAB artifact: 64,207,679 bytes, SHA-256 `a41443b46c2770019d42cd526250c9efce2e22a6cd86ca5d3e3ebe1c75953ed5`.
- Artifacts are GitHub Actions outputs; the manual GitHub Release job was skipped and no release was published.
- Central lifecycle remains `registered` and source-index strategy remains `none`. CI generation/consumption is verified, but automatic runtime artifact provisioning and cross-project isolation remain open gates. Manual Android device acceptance is also pending.


## 2026-11-25 — documentation PR #13 and final post-merge CI
- PR #13 reconciled the project memory with PR #12's source-index checks and the remaining runtime/device gates; merged as `423e45439fd6dbe0744c93eefc336161f16ed119`. No application source or app version changed.
- Post-merge Project Validation run `45668908682` succeeded on that exact main SHA.
- Post-merge APK/AAB build run `45668908595` succeeded on the same SHA. Latest APK: 31,256,271 bytes, SHA-256 `27188007a8fffb7bc00c38df59ddaba1b412865bfd45ce8f82372612bece8537`. Latest AAB: 64,207,679 bytes, SHA-256 `b0762cb3b27211cabb1692d9e2a8d1f6606736d71629910e9c4cb4819a3a1e34`.
- The manual GitHub Release job was not invoked; no Release was published.
- Version remains `1.0.9+10`. Manual Android device acceptance, automatic runtime index provisioning/retrieval, and cross-project isolation remain outstanding.


## 2026-11-25 — reusable cross-repository read-only task intake
- Central PR #130 introduced a reusable GitHub Actions `workflow_call` intake workflow and a read-only registered-project intake state; it merged as `7b2d7dab0d374eed2d0d6745546f4bc2f6e266a0`.
- The intake workflow checks out the calling repository and trusted central tooling separately. V2 task identity is validated against the central project registry and the target repository's live GitHub metadata.
- Registered projects may create a validated inbox artifact marked `validated-awaiting-activation`; this does not claim a lease, invoke a model, upload source, or permit implementation. Lease and handoff paths still require an active lifecycle.
- This target-side workflow change calls the reusable workflow with read-only `contents` and `issues` permissions. No application source, app version, signing, build/release, or production behavior is changed.
- Remaining work: complete exact-head CI for this caller workflow; add the workflow path to the trusted Hesabgar manifest's protected paths; implement the separate reusable lease/handoff workflow and automatic runtime index provisioning only after their target-checkout and freshness tests are ready.


## 2026-11-25 — PR #15 post-merge verification
- PR #15 merged as `7b008f8c5fb493db40ba04ad0d3c556176085471`. It adds the read-only target Issue intake caller for the reusable central workflow; no application source or app version changed.
- Post-merge Flutter Project Validation run `45675484236` succeeded on the exact main SHA.
- Post-merge APK/AAB build run `45675484248` succeeded on the same SHA. APK: 31,256,270 bytes, artifact digest `sha256:1024afef9038f3a988234812c5d2c96a7e08a8fea4a8805f6137175b6b362cea`. AAB: 64,207,679 bytes, artifact digest `sha256:70049376081927718350a708b4993636973ae64ddc3b4fdd5ea7bc0d0f1a3c08`.
- These are GitHub Actions artifacts, not a published Release. No release job was invoked.
- The central manifest protects the target intake workflow. Central PR #131's actual-manifest integration test passed; a registered task is read-only and remains `validated-awaiting-activation`.
- At the PR #15 checkpoint, the GitHub Issue-triggered reusable workflow had not yet been exercised. That earlier status was superseded by the live Issue test recorded below; lease claims, agent dispatch, runtime index provisioning, and Android device acceptance remain blocked/pending.


## 2026-11-25 — live cross-repository Issue intake and deduplication
- PR #16 merged as `a8f8ca8edaab67217e0779c0579a1a703f07ac32`; its exact-head validation succeeded. Post-merge validation run `45677317662` succeeded, and build run `45677317842` succeeded. APK: 31,256,257 bytes, SHA-256 `291cab4e9f1a703f5f942da0c420b3eafe409a82d0aa5219ec99994e93541bbc`; AAB: 64,207,679 bytes, SHA-256 `102af867f1f118ba0074bcb43b1b74fc3c20ebc238dddce70dad1e87cdeb1c22`.
- Live temporary Issue #17 validated task `live-intake-smoke-20261125` and uploaded artifact `agent-task-17` (986 bytes, artifact ID `15052647029`, SHA-256 `684fcf539601637432ee08e861dc929ed989757ab1a47ddbab1cbe9f78471481`). The workflow log explicitly reported: no lease claimed; no model or implementation agent invoked.
- The initial live attempt exposed duplicate `opened` and `labeled` event runs. The first test payload was rejected fail-closed because its manifest digest was incorrect; after correcting the canonical SHA-256 binding, the read-only intake succeeded.
- Central PR #132 merged as `eb2ade7c18e5af3bafc67f7ee73613465d110e6d`, adding exact-payload regression coverage and safe mismatch-field diagnostics. Central PR #134 merged as `cd6c0f2f70927f67d11bdf00c3a84fcf187d4bab`, removing `opened` from first-party intake triggers. Target PR #18 merged as `530daceeaea180c9d2e4a3d333e3981a3dddbaad`, changed the target trigger to `labeled`/`edited`, and ensured intake-workflow changes trigger project validation.
- Exact PR #18 validation run `45678323306` passed. A second live test of Issue #17 after the deduplication fix produced exactly one successful intake run `45678817592`; artifact `agent-task-17` was 1,005 bytes, SHA-256 `99734bab30303c3b3c1c9a19c3481a9bd18d180228baddc0111f19196ac524c4`, artifact ID `15053470675`. Issue #17 was closed again.
- Post-PR #18 Project Validation run `45678762925` passed on main SHA `530daceeaea180c9d2e4a3d333e3981a3dddbaad`. APK/AAB build run `45678762986` completed successfully: APK 31,256,262 bytes (`sha256:a674589e10a9c1f740a0c73ab605f6a45f2adb6fa57a288bea37406211c2a5af`); AAB 64,207,679 bytes (`sha256:fcba275bdb9d53f01e60c540996bb7951c189d4c09a523e259caf283b00c8859`). Both are unexpired CI artifacts, not Releases.
- The intake artifact is still only retained in the target repository's Actions artifact store. Automatic central ingestion into a durable task queue, runtime semantic-index provisioning/retrieval, lease/handoff activation gates, and manual Android device acceptance remain open. Manifest lifecycle stays `registered`; source-index strategy stays `none`; app version stays `1.0.9+10`.


## 2026-11-25 — central inbox persistence work
- PR #20 merged as `d1b850c8abbb8bb5f0131c3dc85522bd6e65a8b5`; it reconciles the current main baseline, records the verified live intake deduplication result, and prioritizes durable central ingestion. Exact-head validation run `45679600283` passed.
- Post-PR #18 build run `45678762986` passed and produced unexpired APK/AAB artifacts with SHA-256 digests recorded in CURRENT_STATUS.md.
- Central PR #138 is implementing the read-only durable inbox persistence primitive. It stores validated artifacts under `.agent/inbox/{repository_id}/{issue_number}.json`, uses atomic no-follow writes, revalidates manifest and repository identity, rejects conflicting updates, and deduplicates task IDs. Exact-head checks are pending.
- Automatic artifact transport remains unimplemented. The target workflow's default `GITHUB_TOKEN` is restricted to the target repository and has read-only permissions; it cannot dispatch a workflow or write a durable record in the central repository. A narrowly scoped cross-repository GitHub App/PAT credential or equivalent broker is required. Do not put credentials in manifests or source files.
- Lifecycle remains `registered`, source index strategy remains `none`, app version remains `1.0.9+10`; no lease, agent, model, app source change, or release.


## 2026-11-25 — durable central inbox and authenticated transport
- Central PR #138 merged as `6b465eec6b5c7c67cd2361146c78182e9b969139`. The central importer validates task protocol, repository/Issue identity, current manifest digest and lifecycle, and no-execution flags; it persists atomically under `.agent/inbox/{repository_id}/{issue_number}.json`, is idempotent for identical artifacts, and rejects conflicting records or duplicate task IDs.
- Central PR #141 merged as `3e5409e5dd6991ec3f6921ae1996d53dd6849f8d`. The transport workflow validates the registered repository, artifact identity/name/size/expiry, workflow run and source SHA, safely reads one bounded task JSON entry, and re-fetches the live Issue to verify it is still open, still labeled `agent-task`, and its exact body/task payload has not changed.
- Central workflow stores durable records on the dedicated `task-inbox` branch, not application source or `main`.
- Target PR #22 passes `secrets: inherit` to the reusable intake workflow and pins it to the reviewed central commit. Its exact-head CI is pending.
- Automatic transport requires two separate least-privilege fine-grained tokens: `JET_AI_CENTRAL_DISPATCH_TOKEN` is scoped only to the central repository with `Contents: write`; `JET_AI_CROSS_REPO_READ_TOKEN` is scoped only to registered target repositories with `Actions: read` and `Issues: read`. Store the first as a secret in each target repository and the second as a secret in the central repository. Do not reuse one token across both trust boundaries.
- No token was committed; no lease, agent, or model was invoked. Hesabgar remains `registered`, source-index strategy `none`, app version `1.0.9+10`; no app source or release change.


## 2026-11-25 — authenticated dispatch caller merged
- Target PR #22 merged as `4195c58176bab1d0eab2d614d0125913c5e30f09`. It passes inherited secrets to the reusable central intake workflow and pins it to central commit `3e5409e5dd6991ec3f6921ae1996d53dd6849f8d`.
- Exact-head target PR validation run `45685677330` passed. Post-merge validation run `45685997204` and APK/AAB build run `45685997149` were still in progress when this log entry was drafted.
- End-to-end dispatch is still opt-in until two separate fine-grained tokens are configured: target secret `JET_AI_CENTRAL_DISPATCH_TOKEN` scoped only to central Contents write; central secret `JET_AI_CROSS_REPO_READ_TOKEN` scoped only to target Actions read + Issues read.
- No secret was created or shared in chat. Until setup, target intake continues to upload its read-only artifact and emits a warning that central dispatch is skipped.


## 2026-11-25 — live test of the pinned central-dispatch caller
- Central PR #142 merged as `a67ce545db259a94bc4ec243d4ec2858dbb80455`. It uses per-repository/per-Issue concurrency and retries pushes to the shared `task-inbox` branch after rebasing, avoiding a single global pending slot.
- Target PR #22 merged as `4195c58176bab1d0eab2d614d0125913c5e30f09`, passing inherited secrets and pinning the reusable workflow to central commit `3e5409e5dd6991ec3f6921ae1996d53dd6849f8d`.
- A fresh live test after PR #22 ran as `45687022313` and succeeded. Artifact `agent-task-17`: 1,005 bytes, SHA-256 `a59c8a2eb941a112255666e1b8b7c3582a82bc764688088eec372f46dd22d0e2`, artifact ID `15056447830`.
- The reusable workflow's optional central dispatch step was skipped because target secret `JET_AI_CENTRAL_DISPATCH_TOKEN` is not configured. The workflow emitted its expected warning; artifact upload and validation still succeeded. No central inbox record was created, no lease was claimed, and no model/agent was invoked.
- Temporary Issue #17 was closed after the retest. To activate automatic transport, configure two separate fine-grained tokens: target secret `JET_AI_CENTRAL_DISPATCH_TOKEN` (central Contents write only) and central secret `JET_AI_CROSS_REPO_READ_TOKEN` (target Actions read + Issues read only). Never paste either token into chat or commit them.
- Post-merge target validation `45686596443` succeeded. Post-merge APK/AAB build `45686596413` was still running when this entry was drafted.


## 2026-11-25 — corrected immutable reusable checkout and final live retest
- Central PR #143's first nested-checkout pin used `github.workflow_sha`; live target run `45688896962` proved it resolved to the caller repository SHA and failed closed before intake. No artifact or task record was created.
- Central PR #144 merged as `798537245da039217010ab750f95561060bd5f76`, pinning nested tooling checkout to explicit immutable central commit `053c1f6e3a695cc8675bc90a679c554ed0e83f18`. Exact-head tests, validation, memory audit, and lease/scope guard all passed.
- Target PR #28 merged as `38057c24504d45829ad3df6f6006c6c04d300f2b`, updating the caller to central PR #144's corrected workflow. Exact-head target project validation run `45689597938` passed.
- Final live Issue #17 retest run `45689900709` succeeded, including the explicit immutable central checkout. Artifact `agent-task-17`: 1,005 bytes, SHA-256 `69ed63eac70223e14cea671aa4171d2766e3df063234a8ce859022cf321d1634`, artifact ID `15058605893`.
- Central dispatch was skipped because `JET_AI_CENTRAL_DISPATCH_TOKEN` is not configured. The target workflow emitted the expected warning; no central inbox record was created, no lease was claimed, and no agent/model was invoked. Temporary Issue #17 was closed again.
- Post-PR #28 target main validation `45689865694` and APK/AAB build `45689865817` were still running when this log entry was written.
- Remaining external setup: two separate least-privilege fine-grained tokens. The target secret `JET_AI_CENTRAL_DISPATCH_TOKEN` must be scoped only to central `Contents: write`; the central secret `JET_AI_CROSS_REPO_READ_TOKEN` must be scoped only to registered targets' `Actions: read` + `Issues: read`. Do not send credentials in chat or commit them.


## 2026-11-26 — PR #30 and current-main checkpoint
- Target PR #30 clarified the cross-repository credential boundary: two separate fine-grained tokens are required, not one reused token.
- Exact-head validation run PR validation run `45690735051` succeeded on PR head `01dc9688363cfede7af9974906356cb6976baf40`.
- PR #30 squash-merged as `76c26c6247873228745c45aad5c3df194669054c`.
- Post-merge validation run `45740186844` and APK/AAB build run `45740186841` started on that exact main SHA; both were still running when this entry was recorded.
- No app source/version/signing/release changes. Lifecycle remains `registered`; source-index strategy remains `none`.
- External gate remains: configure target `JET_AI_CENTRAL_DISPATCH_TOKEN` with central `Contents: write` only, and central `JET_AI_CROSS_REPO_READ_TOKEN` with registered-target `Actions: read` + `Issues: read` only. Do not reuse credentials across repositories or share them in chat.
- Runtime source-index provisioning, end-to-end multi-repository isolation, lease/handoff, and Android device acceptance remain pending.
