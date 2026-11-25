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
- The GitHub Issue-triggered reusable workflow has not yet been exercised with a live Issue event. Lease claims, agent dispatch, runtime index provisioning, and Android device acceptance remain blocked/pending.
