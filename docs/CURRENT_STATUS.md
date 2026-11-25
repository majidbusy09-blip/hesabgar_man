# Current Status — حسابگر من

## Verified baseline
- Target repository: `majidbusy09-blip/hesabgar_man` (immutable GitHub repository ID: `1423683236`).
- Default branch: `main`.
- Current main baseline: `eb121f6db859da4eac495cb2d7d0b5f4e95355b1` (PR #10 merge).
- App version in `pubspec.yaml`: `1.0.9+10` (unchanged).
- Package: `hesabgar_man`.
- The dedicated validation workflow pins Flutter `3.27.4`; Dart is supplied by that Flutter toolchain.

## Repository structure and release safety
- Application source: `lib/`; automated tests: `test/`.
- Build workflow: `.github/workflows/build.yml`.
- Dedicated validation workflow: `.github/workflows/project-validation.yml`.
- Ordinary builds may produce APK/AAB workflow artifacts. GitHub Release publication is a separate manual-only job on `main`, requiring `workflow_dispatch` with `publish_release=true`. Ordinary pushes and PR validation do not publish a Release.
- No app version increment, signing change, store upload, production change, or Release publication was performed in this work.

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
- Release-safety gate PR #3, documentation/CI path-filter PR #4, project-bound resolved-index PR #5, and Task Intelligence smoke-test PR #6 were merged after their exact-head validations passed.
- Run #25 validated the actual Hesabgar checkout against immutable repository ID `1423683236` and a pinned source SHA, generated a project-bound resolved index and curated application-startup critical-path report, and exercised central context selection and impact analysis against `lib/main.dart`.
- The prior generated source index covered 6 Dart files and reported 1,637 declarations, 9,205 call sites, 9,094 resolved calls, 111 unresolved calls, 1,524 internal edges, and zero analyzer errors. These are historical measurements for that pinned source revision, not a claim about every later revision.
- Project-bound index artifacts are CI outputs only; generated JSON is not committed into application source.
- PR #10 added the verified `pubspec.lock` and merged as `eb121f6db859da4eac495cb2d7d0b5f4e95355b1`. The lockfile SHA-256 is `5e758df74d809f0b11c56f834364456d16d7d1bf48534312bc08dd84fa542cac`.
- Exact PR-head validation run `45638699722` succeeded on commit `98717764193fc3e46a4d43966b113b49eeebf062`, including dependency resolution, source-index/critical-path/task-intelligence smoke checks, static analysis, and tests.
- Post-merge validation on current `main` is running: [run 45642260366](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45642260366).
- Post-merge APK/AAB build is running: [run 45642260517](https://github.com/majidbusy09-blip/hesabgar_man/actions/runs/45642260517). Do not treat either as passed until its exact run concludes successfully.

## JET AI onboarding and remaining acceptance
- Central project manifest remains `lifecycle=registered`; `source_index.strategy=none` is intentionally unchanged pending an explicit compatibility decision and review.
- Central project-scoped context cache is implemented and wired into the task preparation path. Cache tests cover round-trip, project namespace separation, source/input drift, corruption rejection, and cache-hit/rebuild behavior. Handoff revalidation deliberately rebuilds context from the pinned Git tree without trusting the cache.
- Central namespace/file-I/O hardening has passed exact-head validation; it does not activate project execution.
- Remaining gates: successful post-merge validation and APK/AAB build, independent source-index adapter/strategy review, and manual Android installation/device acceptance by the owner. CI success alone is not device acceptance.
