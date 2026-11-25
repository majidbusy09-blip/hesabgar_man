# Architecture and Product Decisions — حسابگر من

## 2026-11-25 — Project onboarding decisions
- The stable JET AI project identifier is `hesabgar-man`; the immutable GitHub repository ID is `1423683236`.
- Initial lifecycle is `registered`, not `active`. Registration metadata does not itself authorize implementation or activation.
- The inspected app version `1.0.9+10` is preserved. Version increments require an explicit owner request.
- Persian-first RTL UI is the product baseline.
- Financial and expense data remain local-first. New external data flows require explicit privacy and product review.
- Flutter analysis and tests run in a dedicated pull-request workflow with read-only repository permissions and a pinned Flutter version. Release/build publishing remains separate.
- Automated CI is not a substitute for manual Android-device acceptance.
- The inspected repository had no committed `pubspec.lock`; dependency reproducibility is therefore not yet fully pinned and must remain visible as a limitation until addressed.
