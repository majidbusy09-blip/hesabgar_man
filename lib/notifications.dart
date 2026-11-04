import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// اعلان واقعی سیستم‌عامل (اندروید)
class AppNotifications {
  AppNotifications._();
  static final AppNotifications instance = AppNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool get isReady => _ready;

  /// payload آخرین اعلان لمس‌شده (مثلاً check:id) تا UI باز کند
  static String? pendingPayload;
  void Function(String payload)? onNotificationTap;

  static const _channelId = 'hesabgar_reminders';
  static const _channelName = 'یادآوری حسابگر من';
  static const _channelDesc = 'اقساط تسهیلات و رویدادهای تقویم';

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Tehran'));
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (resp) {
          final p = resp.payload;
          if (p == null || p.isEmpty) return;
          pendingPayload = p;
          onNotificationTap?.call(p);
        },
      );

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ),
      );
      // مجوز اینجا درخواست نمی‌شود؛ فقط هنگام فعال‌کردن یادآوری

      _ready = true;
    } catch (e) {
      debugPrint('AppNotifications.init: $e');
      _ready = false;
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) await init();
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ok = await android?.requestNotificationsPermission();
    return ok ?? false;
  }

  /// فقط هنگام نیاز به یادآوری فراخوانی شود (نه در استارت اپ)
  Future<bool> ensurePermissionForReminders({BuildContext? context}) async {
    if (!_ready) await init();
    if (!_ready) return false;
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ?? false;
    if (!granted && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'برای یادآوری، اجازه اعلان را در تنظیمات برنامه فعال کنید.',
          style: TextStyle(fontFamily: 'Vazirmatn'),
        ),
        duration: Duration(seconds: 4),
      ));
    }
    return granted;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
      );

  /// زمان‌بندی یک اعلان. خروجی: true=موفق، false=رد/شکست
  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    if (!_ready) await init();
    if (!_ready) {
      debugPrint('schedule($id): plugin not ready');
      return false;
    }
    if (when.isBefore(DateTime.now().add(const Duration(seconds: 30)))) {
      debugPrint('schedule($id): time in the past');
      return false;
    }
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    // اول exact، در شکست → inexact (روش متفاوت)
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      return true;
    } catch (e) {
      debugPrint('schedule exact($id): $e — fallback inexact');
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzWhen,
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        return true;
      } catch (e2) {
        debugPrint('schedule failed($id): $e2');
        return false;
      }
    }
  }

  Future<void> cancel(int id) async {
    try {
      if (!_ready) await init();
      if (!_ready) return;
      await _plugin.cancel(id);
    } catch (e) {
      // باگ شناخته‌شده برخی نسخه‌های پلاگین (Missing type parameter)
      // نباید ذخیره داده کاربر را خراب کند
      debugPrint('AppNotifications.cancel($id): $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      if (!_ready) await init();
      if (!_ready) return;
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('AppNotifications.cancelAll: $e');
    }
  }

  /// شناسه پایدار برای قسط (محدودهٔ امن int32)
  static int loanNotifId(String loanId, int index, {bool dayBefore = false}) {
    final base = loanId.hashCode.abs() % 100000;
    final n = base * 100 + (index % 90) + (dayBefore ? 1 : 0);
    return n % 2147483647;
  }

  static int eventNotifId(String eventId) {
    return (eventId.hashCode.abs() % 2000000000) + 1;
  }

  /// زمان‌بندی اقساط یک تسهیلات
  Future<void> scheduleLoanInstallments({
    required String loanId,
    required String title,
    required double amount,
    required List<DateTime> paymentDates,
    required bool sameDay,
    required bool dayBefore,
  }) async {
    if (!_ready) await init();
    // لغو قبلی در بازهٔ این وام (تقریبی)
    for (var i = 0; i < paymentDates.length; i++) {
      await cancel(loanNotifId(loanId, i, dayBefore: false));
      await cancel(loanNotifId(loanId, i, dayBefore: true));
    }
    for (var i = 0; i < paymentDates.length; i++) {
      final day = paymentDates[i];
      final payMorning = DateTime(day.year, day.month, day.day, 9, 0);
      if (sameDay) {
        await schedule(
          id: loanNotifId(loanId, i),
          title: 'قسط: $title',
          body: 'امروز موعد قسط ${i + 1} است.',
          when: payMorning,
        );
      }
      if (dayBefore) {
        final before = payMorning.subtract(const Duration(days: 1));
        await schedule(
          id: loanNotifId(loanId, i, dayBefore: true),
          title: 'فردا قسط: $title',
          body: 'فردا موعد پرداخت قسط ${i + 1} است.',
          when: before,
        );
      }
    }
  }

  /// حداکثر اعلان آینده برای یک رویداد تکراری (محدودیت عملی اندروید)
  static const int maxRecurringNotifs = 5;

  static int eventOccurrenceNotifId(String eventId, int index) {
    final base = eventNotifId(eventId);
    return (base + index * 17) % 2147483647;
  }

  /// لغو همهٔ اعلان‌های یک رویداد (پایه + تکرار)
  Future<void> cancelEventReminders(String eventId) async {
    await cancel(eventNotifId(eventId));
    for (var i = 0; i < maxRecurringNotifs; i++) {
      await cancel(eventOccurrenceNotifId(eventId, i));
    }
  }

  /// زمان‌بندی یادآوری. برای تکرار: تا [maxRecurringNotifs] وقوع آینده.
  /// [nextStarts] لیست زمان شروع وقوع‌های آینده (از قبل محاسبه شده).
  Future<bool> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime start,
    required int reminderMinutes,
    List<DateTime>? nextStarts,
  }) async {
    await cancelEventReminders(eventId);
    if (reminderMinutes <= 0) return true;

    final starts = (nextStarts == null || nextStarts.isEmpty)
        ? <DateTime>[start]
        : nextStarts.take(maxRecurringNotifs).toList();

    var anyOk = false;
    var anyFail = false;
    for (var i = 0; i < starts.length; i++) {
      final when = starts[i].subtract(Duration(minutes: reminderMinutes));
      final ok = await schedule(
        id: eventOccurrenceNotifId(eventId, i),
        title: 'یادآوری: $title',
        body: reminderMinutes >= 1440 ? 'فردا: $title' : 'به‌زودی: $title',
        when: when,
      );
      if (ok) {
        anyOk = true;
      } else {
        anyFail = true;
      }
    }
    if (anyFail && !anyOk) return false;
    return true;
  }
}
