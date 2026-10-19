/// جمع و تفریق اعداد مرکب (مخصوص دانش‌آموزان)
/// مثال: ۲ ساعت و ۴۵ دقیقه + ۱ ساعت و ۳۰ دقیقه

class CompoundUnitDef {
  final String name;
  final int base; // نسبت به واحد کوچک‌تر بعدی (مثلاً دقیقه=60 ثانیه)
  const CompoundUnitDef(this.name, this.base);
}

class CompoundSystem {
  final String id;
  final String title;
  final String emoji;
  final List<CompoundUnitDef> units; // از بزرگ به کوچک

  const CompoundSystem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.units,
  });

  /// تبدیل لیست مقادیر (هم‌اندازه units) به کوچک‌ترین واحد
  int toSmallest(List<int> values) {
    assert(values.length == units.length);
    var total = 0;
    for (var i = 0; i < values.length; i++) {
      total = total * units[i].base + values[i];
      // برای آخرین واحد base معمولاً ۱ است
    }
    // اصلاح: units[i].base یعنی «چند واحد کوچک‌تر در این واحد»
    // محاسبه صحیح از بزرگ به کوچک:
    return _toSmallestCorrect(values);
  }

  int _toSmallestCorrect(List<int> values) {
    // units: [ساعت base=60, دقیقه base=60, ثانیه base=1]
    // total_seconds = h*3600 + m*60 + s
    var total = 0;
    var factor = 1;
    // اول ضریب‌ها را از کوچک به بزرگ بساز
    final factors = List<int>.filled(units.length, 1);
    for (var i = units.length - 2; i >= 0; i--) {
      factors[i] = factors[i + 1] * units[i].base;
    }
    // units[i].base = تعداد واحد i+1 در یک واحد i
    for (var i = 0; i < units.length; i++) {
      total += values[i] * factors[i];
    }
    return total;
  }

  List<int> fromSmallest(int total) {
    final result = List<int>.filled(units.length, 0);
    final factors = List<int>.filled(units.length, 1);
    for (var i = units.length - 2; i >= 0; i--) {
      factors[i] = factors[i + 1] * units[i].base;
    }
    var remaining = total;
    if (remaining < 0) remaining = -remaining;
    for (var i = 0; i < units.length; i++) {
      result[i] = remaining ~/ factors[i];
      remaining %= factors[i];
    }
    return result;
  }

  bool isNegative(int total) => total < 0;

  /// جمع
  CompoundResult add(List<int> a, List<int> b) {
    final sum = toSmallest(a) + toSmallest(b);
    return CompoundResult(
      values: fromSmallest(sum),
      negative: sum < 0,
      totalSmallest: sum,
    );
  }

  /// تفریق a - b
  CompoundResult subtract(List<int> a, List<int> b) {
    final diff = toSmallest(a) - toSmallest(b);
    return CompoundResult(
      values: fromSmallest(diff),
      negative: diff < 0,
      totalSmallest: diff,
    );
  }

  String format(List<int> values, {bool negative = false}) {
    final parts = <String>[];
    for (var i = 0; i < units.length; i++) {
      if (values[i] != 0 || i == units.length - 1) {
        parts.add('${values[i]} ${units[i].name}');
      }
    }
    final s = parts.join(' و ');
    return negative ? '− $s' : s;
  }
}

class CompoundResult {
  final List<int> values;
  final bool negative;
  final int totalSmallest;
  const CompoundResult({
    required this.values,
    required this.negative,
    required this.totalSmallest,
  });
}

class CompoundSystems {
  static final all = <CompoundSystem>[
    CompoundSystem(
      id: 'time',
      title: 'زمان',
      emoji: '⏱️',
      units: const [
        CompoundUnitDef('ساعت', 60),
        CompoundUnitDef('دقیقه', 60),
        CompoundUnitDef('ثانیه', 1),
      ],
    ),
    CompoundSystem(
      id: 'length',
      title: 'طول',
      emoji: '📏',
      units: const [
        CompoundUnitDef('متر', 100),
        CompoundUnitDef('سانتی‌متر', 10),
        CompoundUnitDef('میلی‌متر', 1),
      ],
    ),
    CompoundSystem(
      id: 'length_km',
      title: 'طول (کیلومتر)',
      emoji: '🛣️',
      units: const [
        CompoundUnitDef('کیلومتر', 1000),
        CompoundUnitDef('متر', 100),
        CompoundUnitDef('سانتی‌متر', 1),
      ],
    ),
    CompoundSystem(
      id: 'weight',
      title: 'وزن',
      emoji: '⚖️',
      units: const [
        CompoundUnitDef('کیلوگرم', 1000),
        CompoundUnitDef('گرم', 1000),
        CompoundUnitDef('میلی‌گرم', 1),
      ],
    ),
    CompoundSystem(
      id: 'angle',
      title: 'زاویه',
      emoji: '📐',
      units: const [
        CompoundUnitDef('درجه', 60),
        CompoundUnitDef('دقیقه', 60),
        CompoundUnitDef('ثانیه', 1),
      ],
    ),
    CompoundSystem(
      id: 'day_time',
      title: 'روز و ساعت',
      emoji: '📅',
      units: const [
        CompoundUnitDef('روز', 24),
        CompoundUnitDef('ساعت', 60),
        CompoundUnitDef('دقیقه', 1),
      ],
    ),
  ];
}
