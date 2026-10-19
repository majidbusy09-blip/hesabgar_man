class UnitItem {
  final String id;
  final String name;
  final double toBase; // ضریب تبدیل به واحد پایه
  final double Function(double)? customToBase;
  final double Function(double)? customFromBase;

  const UnitItem(this.id, this.name, this.toBase, {this.customToBase, this.customFromBase});
}

class UnitCategory {
  final String id;
  final String name;
  final String emoji;
  final List<UnitItem> units;

  const UnitCategory(this.id, this.name, this.emoji, this.units);
}

class UnitData {
  static final categories = <UnitCategory>[
    UnitCategory('length', 'طول', '📏', [
      UnitItem('m', 'متر', 1),
      UnitItem('km', 'کیلومتر', 1000),
      UnitItem('cm', 'سانتی‌متر', 0.01),
      UnitItem('mm', 'میلی‌متر', 0.001),
      UnitItem('mi', 'مایل', 1609.344),
      UnitItem('yd', 'یارد', 0.9144),
      UnitItem('ft', 'فوت', 0.3048),
      UnitItem('in', 'اینچ', 0.0254),
    ]),
    UnitCategory('area', 'سطح', '⬜', [
      UnitItem('m2', 'متر مربع', 1),
      UnitItem('km2', 'کیلومتر مربع', 1e6),
      UnitItem('ha', 'هکتار', 10000),
      UnitItem('acre', 'جریب (Acre)', 4046.856),
      UnitItem('ft2', 'فوت مربع', 0.092903),
      UnitItem('cm2', 'سانتی‌متر مربع', 0.0001),
    ]),
    UnitCategory('volume', 'حجم', '🧪', [
      UnitItem('l', 'لیتر', 1),
      UnitItem('ml', 'میلی‌لیتر', 0.001),
      UnitItem('m3', 'متر مکعب', 1000),
      UnitItem('gal', 'گالن (US)', 3.78541),
      UnitItem('qt', 'کوارت', 0.946353),
      UnitItem('cup', 'فنجان', 0.236588),
    ]),
    UnitCategory('mass', 'جرم', '⚖️', [
      UnitItem('kg', 'کیلوگرم', 1),
      UnitItem('g', 'گرم', 0.001),
      UnitItem('mg', 'میلی‌گرم', 1e-6),
      UnitItem('t', 'تن', 1000),
      UnitItem('lb', 'پوند', 0.453592),
      UnitItem('oz', 'اونس', 0.0283495),
    ]),
    UnitCategory('temp', 'دما', '🌡️', [
      UnitItem('c', 'سلسیوس', 1,
          customToBase: (v) => v,
          customFromBase: (v) => v),
      UnitItem('f', 'فارنهایت', 1,
          customToBase: (v) => (v - 32) * 5 / 9,
          customFromBase: (v) => v * 9 / 5 + 32),
      UnitItem('k', 'کلوین', 1,
          customToBase: (v) => v - 273.15,
          customFromBase: (v) => v + 273.15),
    ]),
    UnitCategory('speed', 'سرعت', '🚀', [
      UnitItem('mps', 'متر بر ثانیه', 1),
      UnitItem('kmh', 'کیلومتر بر ساعت', 1 / 3.6),
      UnitItem('mph', 'مایل بر ساعت', 0.44704),
      UnitItem('knot', 'گره', 0.514444),
    ]),
    UnitCategory('time', 'زمان', '⏱️', [
      UnitItem('s', 'ثانیه', 1),
      UnitItem('min', 'دقیقه', 60),
      UnitItem('h', 'ساعت', 3600),
      UnitItem('day', 'روز', 86400),
      UnitItem('week', 'هفته', 604800),
      UnitItem('ms', 'میلی‌ثانیه', 0.001),
    ]),
    UnitCategory('data', 'داده', '💾', [
      UnitItem('b', 'بایت', 1),
      UnitItem('kb', 'کیلوبایت', 1024),
      UnitItem('mb', 'مگابایت', 1048576),
      UnitItem('gb', 'گیگابایت', 1073741824),
      UnitItem('tb', 'ترابایت', 1099511627776),
      UnitItem('bit', 'بیت', 0.125),
    ]),
    UnitCategory('pressure', 'فشار', '💨', [
      UnitItem('pa', 'پاسکال', 1),
      UnitItem('kpa', 'کیلوپاسکال', 1000),
      UnitItem('bar', 'بار', 100000),
      UnitItem('atm', 'اتمسفر', 101325),
      UnitItem('psi', 'PSI', 6894.76),
      UnitItem('mmhg', 'میلی‌متر جیوه', 133.322),
    ]),
    UnitCategory('energy', 'انرژی', '⚡', [
      UnitItem('j', 'ژول', 1),
      UnitItem('kj', 'کیلوژول', 1000),
      UnitItem('cal', 'کالری', 4.184),
      UnitItem('kcal', 'کیلوکالری', 4184),
      UnitItem('wh', 'وات‌ساعت', 3600),
      UnitItem('kwh', 'کیلووات‌ساعت', 3600000),
    ]),
    UnitCategory('angle', 'زاویه', '📐', [
      UnitItem('deg', 'درجه', 1),
      UnitItem('rad', 'رادیان', 57.2957795),
      UnitItem('grad', 'گراد', 0.9),
    ]),
  ];

  static double convert({
    required UnitCategory category,
    required UnitItem from,
    required UnitItem to,
    required double value,
  }) {
    if (from.id == to.id) return value;

    // دما واحد پایه = سلسیوس
    if (category.id == 'temp') {
      final celsius = from.customToBase != null
          ? from.customToBase!(value)
          : value;
      return to.customFromBase != null
          ? to.customFromBase!(celsius)
          : celsius;
    }

    final base = value * from.toBase;
    return base / to.toBase;
  }
}
