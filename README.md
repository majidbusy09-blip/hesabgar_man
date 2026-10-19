# حسابگر من (hesabgar_man)

ماشین‌حساب علمی و ابزارهای مالی شخصی — اپلیکیشن Flutter با رابط فارسی.

## امکانات

### ماشین‌حساب
- حالت ساده و علمی
- حافظه (MC / MR / M+ / M−)
- DEG / RAD
- تاریخچه و تایپ دستی فرمول
- پشتیبانی landscape

### محاسبات مالی
- محاسبه قسط وام
- سود مرکب سپرده
- مالیات بر ارزش افزوده (عادی و معکوس)

### هزینه‌ها
- ثبت هزینه با دسته‌بندی
- ذخیره محلی با SharedPreferences
- حذف با سوایپ

### تقویم
- تقویم شمسی ماهانه
- نمایش امروز و معادل میلادی

### تنظیمات
- تم روشن / تاریک / سیستم

## اجرا

```bash
flutter pub get
# فونت Vazirmatn را در assets/fonts قرار دهید:
#   Vazirmatn-Regular.ttf
#   Vazirmatn-Medium.ttf
#   Vazirmatn-Bold.ttf
flutter run
```

## ساختار

```
lib/
  core/theme/          تم و رنگ‌ها
  core/providers/      ThemeProvider
  features/
    calculator/        ماشین‌حساب
    finance/           محاسبات مالی
    expenses/          ردیاب هزینه
    calendar/          تقویم شمسی
    settings/          تنظیمات
  shared/widgets/      MainScaffold
```

## بیلد APK

با GitHub Actions روی push به `main` به‌صورت خودکار بیلد می‌شود.
