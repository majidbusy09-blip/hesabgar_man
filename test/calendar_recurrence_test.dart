import 'package:flutter_test/flutter_test.dart';
import 'package:hesabgar_man/calendar_v2.dart';
import 'package:hesabgar_man/features.dart' show Jalali;
import 'package:hesabgar_man/notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CalendarStore store;

  /// DateTime ظهر برای جلوگیری از شیفت UTC در CI
  DateTime noon(int y, int m, int d) => DateTime(y, m, d, 12);

  DateTime fromJalali(int jy, int jm, int jd) {
    final j = Jalali(jy, jm, jd);
    final g = j.toDateTime();
    return noon(g.year, g.month, g.day);
  }

  setUp(() {
    store = CalendarStore();
    store.events = [];
    store.notes = [];
    store.tasks = [];
    store.lastError = null;
  });

  CalEvent ev({
    required String id,
    required DateTime start,
    String recurrence = 'none',
    DateTime? until,
    DateTime? end,
  }) {
    return CalEvent(
      id: id,
      title: 't',
      start: start,
      end: end,
      recurrence: recurrence,
      recurrenceUntil: until,
      allDay: end == null,
    );
  }

  group('occurrencesOn', () {
    test('بدون تکرار فقط همان روز', () {
      store.events = [ev(id: '1', start: noon(2026, 3, 10))];
      expect(store.occurrencesOn(noon(2026, 3, 10)).length, 1);
      expect(store.occurrencesOn(noon(2026, 3, 11)), isEmpty);
    });

    test('روزانه بعد از بیش از ۴۰۰ روز', () {
      final start = noon(2024, 1, 1);
      store.events = [
        CalEvent(
          id: 'd',
          title: 't',
          start: DateTime(2024, 1, 1, 8, 15),
          recurrence: 'daily',
          allDay: false,
        ),
      ];
      final far = start.add(const Duration(days: 500));
      final list = store.occurrencesOn(far);
      expect(list.length, 1);
      expect(list.first.start.day, far.day);
      expect(list.first.start.hour, 8);
      expect(list.first.start.minute, 15);
    });

    test('هفتگی در آینده دور', () {
      final start = noon(2025, 1, 6);
      store.events = [ev(id: 'w', start: start, recurrence: 'weekly')];
      final far = start.add(const Duration(days: 7 * 80));
      expect(store.occurrencesOn(far).length, 1);
      expect(store.occurrencesOn(far.add(const Duration(days: 1))), isEmpty);
    });

    test('ماهانه روز ۳۱ شمسی در ماه ۳۰ روزه', () {
      final start = fromJalali(1403, 6, 31); // ۳۱ شهریور
      store.events = [ev(id: 'm', start: start, recurrence: 'monthly')];
      final mehr30 = fromJalali(1403, 7, 30);
      expect(store.occurrencesOn(mehr30).length, 1);
      expect(store.occurrencesOn(fromJalali(1403, 7, 29)), isEmpty);
    });

    test('سالانه همان روز شمسی در سال‌های بعد', () {
      final start = fromJalali(1400, 1, 15);
      store.events = [ev(id: 'y', start: start, recurrence: 'yearly')];
      expect(store.occurrencesOn(fromJalali(1405, 1, 15)).length, 1);
      expect(store.occurrencesOn(fromJalali(1405, 1, 16)), isEmpty);
      expect(store.occurrencesOn(fromJalali(1399, 1, 15)), isEmpty);
    });

    test('سالانه با clamp وقتی طول ماه مقصد کوتاه‌تر است', () {
      // روز مبدأ: آخرین روز ممکن یک ماه ۳۰ روزه (مثلاً اسفند ۳۰ در سال کبیسه)
      int? startY;
      for (var y = 1390; y < 1415; y++) {
        if (Jalali(y, 12, 1).monthLength == 30) {
          startY = y;
          break;
        }
      }
      expect(startY, isNotNull);
      final start = fromJalali(startY!, 12, 30);
      store.events = [ev(id: 'yc', start: start, recurrence: 'yearly')];

      // سال بعد با اسفند کوتاه‌تر
      int? nextY;
      for (var y = startY + 1; y < startY + 12; y++) {
        if (Jalali(y, 12, 1).monthLength < 30) {
          nextY = y;
          break;
        }
      }
      if (nextY == null) {
        // اگر پیدا نشد، همان سال +1 با clamp
        nextY = startY + 1;
      }
      final len = Jalali(nextY, 12, 1).monthLength;
      final target = 30 > len ? len : 30;
      final next = fromJalali(nextY, 12, target);
      expect(store.occurrencesOn(next).length, 1);
    });

    test('تاریخ پایان تکرار', () {
      final start = noon(2026, 1, 1);
      store.events = [
        ev(
          id: 'u',
          start: start,
          recurrence: 'daily',
          until: noon(2026, 1, 10),
        ),
      ];
      expect(store.occurrencesOn(noon(2026, 1, 10)).length, 1);
      expect(store.occurrencesOn(noon(2026, 1, 11)), isEmpty);
    });

    test('شناسه اعلان پایدار', () {
      expect(
        AppNotifications.eventNotifId('ev_abc'),
        AppNotifications.eventNotifId('ev_abc'),
      );
    });
  });
}
