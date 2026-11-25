# حسابگر من — Project Context

## Product
«حسابگر من» یک اپلیکیشن اندرویدی فارسی‌زبان برای ماشین‌حساب روزمره، علمی و حسابداری و مجموعه‌ای از ابزارهای مالی و شخصی است. تجربه محصول فارسی و راست‌به‌چپ است و فونت Vazirmatn در رابط استفاده می‌شود.

## Verified repository baseline
- Repository: `majidbusy09-blip/hesabgar_man`
- Immutable GitHub repository ID: `1423683236`
- Default branch: `main`
- Current verified baseline: `3e215d93dffc87ec3d759dc557a179d7fb1fc873`
- `pubspec.yaml` version: `1.0.9+10` (preserved; do not bump without explicit owner request)
- Package name: `hesabgar_man`
- Dart SDK constraint: `>=3.0.0 <4.0.0`
- CI Flutter toolchain: `3.27.4`
- Primary source directory: `lib/`
- Automated tests: `test/`

## Application entry and module boundaries
- `lib/main.dart`: Flutter entry point, localization setup, providers, app theme and main scaffold; it initializes notification handling.
- `lib/core.dart`: shared application state, theme/feedback providers and common utilities.
- `lib/features.dart`: calculator, finance, calendar, expenses and settings feature logic/UI. This is currently a large shared module; prefer incremental extraction only when separately scoped.
- `lib/calendar_v2.dart`: calendar implementation.
- `lib/checks.dart`: check-management models and UI.
- `lib/notifications.dart`: local notification setup and routing.
- `assets/brand/`, `assets/fonts/`, `assets/sounds/`, and `assets/banks/`: bundled visual, typography, sound and bank assets.

## Product capabilities documented in the repository
- Basic, scientific and accounting calculator modes; arithmetic history, memory, DEG/RAD angle mode and live result preview.
- Persian (Jalali), Gregorian and Hijri calendar views and date conversion.
- Expense recording with Persian dates.
- Deposit-interest calculation, gold-price lookup and unit conversion.
- Theme customization, including photo-derived theme colors; sound and haptic feedback controls.
- Check-management and local notification modules are present in the source tree.

## Data and network boundaries
- The README states that expense data and settings are stored locally on the device.
- Gold-price retrieval is the documented online data flow.
- Do not broaden network transmission of personal financial data without an explicit privacy review and owner approval.
- Signing configuration and secrets must remain outside source control.

## CI and release boundaries
- `.github/workflows/project-validation.yml` pins Flutter 3.27.4 and runs dependency resolution, static analysis, and tests.
- `.github/workflows/build.yml` may build APK/AAB artifacts on ordinary pushes, but GitHub Release publication is separated into a manual `workflow_dispatch` job that requires explicit `publish_release=true` on `main`.
- The successful validation run for PR head `41476246df42bf7c4147fc79b1d4a656ad6eeeb5` is run `45599635131`.
- The generated lockfile is currently a CI artifact for review; it is not yet committed to `main`.

## Architecture and maintenance
- Keep calculator/finance business logic testable independently of widgets.
- Preserve existing data formats and local storage compatibility unless a migration is explicitly designed and tested.
- Keep notification scheduling, notification payload routing and check identifiers deterministic.
- Avoid changing unrelated screens or feature behavior while fixing a localized defect.
