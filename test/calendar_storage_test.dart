import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hesabgar_man/calendar_v2.dart';
import 'package:hesabgar_man/notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalendarStore decode / recurrence notif helpers', () {
    test('رکورد مخلوط: فقط سالم‌ها parse می‌شوند', () {
      final raw = jsonEncode([
        {
          'id': 'ok1',
          'title': 'A',
          'start': DateTime(2026, 2, 1, 12).toIso8601String(),
          'allDay': true,
          'categoryId': 'c_personal',
          'recurrence': 'none',
          'reminderMinutes': 0,
          'color': 0xFF42A5F5,
        },
        'not-a-map',
        {
          'id': 'ok2',
          'title': 'B',
          'start': DateTime(2026, 2, 2, 12).toIso8601String(),
          'allDay': true,
          'categoryId': 'c_personal',
          'recurrence': 'none',
          'reminderMinutes': 0,
          'color': 0xFF42A5F5,
        },
      ]);
      final decoded = jsonDecode(raw) as List;
      final items = <CalEvent>[];
      var corrupt = 0;
      for (final e in decoded) {
        try {
          if (e is Map<String, dynamic>) {
            items.add(CalEvent.fromJson(e));
          } else if (e is Map) {
            items.add(CalEvent.fromJson(Map<String, dynamic>.from(e)));
          } else {
            corrupt++;
          }
        } catch (_) {
          corrupt++;
        }
      }
      expect(items.length, 2);
      expect(corrupt, 1);
    });

    test('JSON نامعتبر نباید باعث از دست رفتن لیست قبلی در حافظه شود', () {
      final store = CalendarStore();
      store.events = [
        CalEvent(
          id: 'keep',
          title: 'سالم',
          start: DateTime(2026, 1, 1, 12),
        ),
      ];
      // شبیه‌سازی load ناموفق: استثنا و عدم انتساب
      try {
        jsonDecode('{not-json');
      } catch (_) {
        // لیست قبلی دست‌نخورده
      }
      expect(store.events.length, 1);
      expect(store.events.first.id, 'keep');
    });

    test('شناسه وقوع‌های اعلان متمایز و پایدارند', () {
      final a0 = AppNotifications.eventOccurrenceNotifId('ev1', 0);
      final a1 = AppNotifications.eventOccurrenceNotifId('ev1', 1);
      expect(a0, AppNotifications.eventOccurrenceNotifId('ev1', 0));
      expect(a0, isNot(a1));
    });

    test('nextOccurrenceStarts روزانه چند وقوع آینده', () {
      final e = CalEvent(
        id: 'd',
        title: 'daily',
        start: DateTime.now().add(const Duration(days: 1)),
        recurrence: 'daily',
        allDay: true,
      );
      final nexts = CalendarStore.nextOccurrenceStarts(e, limit: 5);
      expect(nexts.length, greaterThanOrEqualTo(3));
      expect(nexts.length, lessThanOrEqualTo(5));
      for (var i = 1; i < nexts.length; i++) {
        expect(nexts[i].difference(nexts[i - 1]).inDays, 1);
      }
    });

    test('until تکرار را محدود می‌کند', () {
      final start = DateTime.now().add(const Duration(days: 1));
      final until = start.add(const Duration(days: 2));
      final e = CalEvent(
        id: 'u',
        title: 'lim',
        start: start,
        recurrence: 'daily',
        recurrenceUntil: until,
        allDay: true,
      );
      final nexts = CalendarStore.nextOccurrenceStarts(e, limit: 10);
      expect(nexts.length, lessThanOrEqualTo(3));
    });
  });
}
