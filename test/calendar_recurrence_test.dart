import 'package:flutter_test/flutter_test.dart';
import 'package:hesabgar_man/calendar_v2.dart';
import 'package:hesabgar_man/features.dart' show Jalali;
import 'package:hesabgar_man/notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CalendarStore store;

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
      store.events = [ev(id: '1', start: DateTime(2026, 3, 10, 9))];
      expect(store.occurrencesOn(DateTime(2026, 3, 10)).length, 1);
      expect(store.occurrencesOn(DateTime(2026, 3, 11)), isEmpty);
    });

    test('روزانه بعد از بیش از ۴۰۰ روز', () {
      final start = DateTime(2024, 1, 1, 8, 15);
      store.events = [ev(id: 'd', start: start, recurrence: 'daily')];
      final far = start.add(const Duration(days: 500));
      final list = store.occurrencesOn(far);
      expect(list.length, 1);
      expect(list.first.start.day, far.day);
      expect(list.first.start.hour, 8);
      expect(list.first.start.minute, 15);
    });

    test('هفتگی در آینده دور', () {
      final start = DateTime(2025, 1, 6);
      store.events = [ev(id: 'w', start: start, recurrence: 'weekly')];
      final far = start.add(const Duration(days: 7 * 80));
      expect(store.occurrencesOn(far).length, 1);
      expect(store.occurrencesOn(far.add(const Duration(days: 1))), isEmpty);
    });

    test('ماهانه روز ۳۱ شمسی در ماه ۳۰ روزه', () {
      // ۳۱ شهریور همیشه وجود دارد
      final start = Jalali(1403, 6, 31).toDateTime();
      store.events = [ev(id: 'm', start: start, recurrence: 'monthly')];
      // مهر ۳۰ روزه است → وقوع روی ۳۰ مهر
      final mehr30 = Jalali(1403, 7, 30).toDateTime();
      expect(store.occurrencesOn(mehr30).length, 1);
      expect(store.occurrencesOn(Jalali(1403, 7, 29).toDateTime()), isEmpty);
    });

    test('سالانه با clamp روز آخر ماه شمسی', () {
      // شروع از روز آخر یک ماه ۳۰ روزه
      final start = Jalali(1403, 12, 29).toDateTime();
      store.events = [ev(id: 'y', start: start, recurrence: 'yearly')];
      final y2len = Jalali(1404, 12, 1).monthLength;
      final day = 29 > y2len ? y2len : 29;
      final next = Jalali(1404, 12, day).toDateTime();
      expect(store.occurrencesOn(next).length, 1);
    });

    test('تاریخ پایان تکرار', () {
      final start = DateTime(2026, 1, 1);
      store.events = [
        ev(
          id: 'u',
          start: start,
          recurrence: 'daily',
          until: DateTime(2026, 1, 10),
        ),
      ];
      expect(store.occurrencesOn(DateTime(2026, 1, 10)).length, 1);
      expect(store.occurrencesOn(DateTime(2026, 1, 11)), isEmpty);
    });

    test('شناسه اعلان پایدار', () {
      expect(
        AppNotifications.eventNotifId('ev_abc'),
        AppNotifications.eventNotifId('ev_abc'),
      );
    });
  });
}
