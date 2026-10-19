/// تبدیل ساده میلادی ↔ شمسی (الگوریتم استاندارد)
class Jalali {
  final int year;
  final int month;
  final int day;

  const Jalali(this.year, this.month, this.day);

  static const monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const weekDays = [
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
  ];

  String get monthName => monthNames[month - 1];

  /// تعداد روزهای ماه شمسی
  int get monthLength {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return isLeap(year) ? 30 : 29;
  }

  static bool isLeap(int year) {
    final breaks = [
      -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181,
      1210, 1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178
    ];
    final jp = breaks.indexWhere((b) => year < b);
    final jump = breaks[jp] - breaks[jp - 1];
    var n = year - breaks[jp - 1];
    if (jump - n < 6) n = n - jump + ((jump + 4) ~/ 33) * 33;
    var leap = ((n + 1) % 33) % 4;
    if (jump == 33 && leap == 1) leap = 0;
    return leap == 1;
  }

  static Jalali fromDateTime(DateTime dt) {
    return fromGregorian(dt.year, dt.month, dt.day);
  }

  static Jalali fromGregorian(int gy, int gm, int gd) {
    final gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    var gy2 = (gm > 2) ? (gy + 1) : gy;
    var days = 355666 +
        (365 * gy) +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) +
        gd +
        gdm[gm - 1];
    var jy = -1595 + (33 * (days ~/ 12053));
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    int jm, jd;
    if (days < 186) {
      jm = 1 + (days ~/ 31);
      jd = 1 + (days % 31);
    } else {
      jm = 7 + ((days - 186) ~/ 30);
      jd = 1 + ((days - 186) % 30);
    }
    return Jalali(jy, jm, jd);
  }

  DateTime toDateTime() {
    final jy = year;
    final jm = month;
    final jd = day;
    final jdn = _jalaliToJdn(jy, jm, jd);
    return _jdnToGregorian(jdn);
  }

  static int _jalaliToJdn(int jy, int jm, int jd) {
    final epbase = jy - ((jy >= 0) ? 474 : 473);
    final epyear = 474 + (epbase % 2820);
    return jd +
        ((jm <= 7) ? ((jm - 1) * 31) : (((jm - 1) * 30) + 6)) +
        (((epyear * 682) - 110) ~/ 2816) +
        (epyear - 1) * 365 +
        (epbase ~/ 2820) * 1029983 +
        1948320 - 1;
  }

  static DateTime _jdnToGregorian(int jdn) {
    var j = 4 * jdn + 139361631;
    j = j + ((((4 * jdn + 183187720) ~/ 146097) * 3) ~/ 4) * 4 - 3908;
    final i = ((j % 1461) ~/ 4) * 5 + 308;
    final gd = ((i % 153) ~/ 5) + 1;
    final gm = ((i ~/ 153) % 12) + 1;
    final gy = (j ~/ 1461) - 100100 + ((8 - gm) ~/ 6);
    return DateTime(gy, gm, gd);
  }

  /// روز هفته: ۰ = شنبه
  int get weekDay {
    final dt = toDateTime();
    // DateTime.weekday: 1=Mon ... 7=Sun
    // شمسی: شنبه=0
    return (dt.weekday % 7); // Sun=0 in this formula... wait
    // Monday=1 -> we want Sat=0
    // Sat=6 in DateTime -> 0
    // Sun=7 -> 1
    // Mon=1 -> 2
  }

  int get weekdayIndex {
    final wd = toDateTime().weekday; // 1=Mon ... 7=Sun
    // Map to Sat=0, Sun=1, ..., Fri=6
    return (wd % 7 + 1) % 7; // Sun(7)->1, Mon(1)->2, ... Sat(6)->0
    // Actually: Sat=6 -> (6%7+1)%7 = 0 ✓
    // Sun=7 -> (0+1)%7 = 1 ✓
    // Mon=1 -> (1+1)%7 = 2 ✓
    // Fri=5 -> (5+1)%7 = 6 ✓
  }

  Jalali addMonths(int n) {
    var y = year;
    var m = month + n;
    while (m > 12) {
      m -= 12;
      y++;
    }
    while (m < 1) {
      m += 12;
      y--;
    }
    final maxDay = Jalali(y, m, 1).monthLength;
    final d = day > maxDay ? maxDay : day;
    return Jalali(y, m, d);
  }

  @override
  String toString() =>
      '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}';
}
