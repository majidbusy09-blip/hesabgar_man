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

  /// شناسه پایدار قسط — بدون String.hashCode (ثابت بین اجراها)
  static int loanNotifId(String loanId, int index, {int daysBefore = 0}) {
    var h = 2166136261;
    for (final u in loanId.codeUnits) {
      h ^= u;
      h = (h * 16777619) & 0x7fffffff;
    }
    final base = h % 800000;
    final d = daysBefore.clamp(0, 30);
    return 320000000 + base * 40 + (index % 40) * 31 + d;
  }

  static int eventNotifId(String eventId) {
    return (eventId.hashCode.abs() % 2000000000) + 1;
  }

  /// زمان‌بندی اقساط یک تسهیلات با روزهای قبل و ساعت دلخواه
  Future<void> scheduleLoanInstallments({
    required String loanId,
    required String title,
    required double amount,
    required List<DateTime> paymentDates,
    required bool sameDay,
    required bool dayBefore,
    List<int>? reminderDays,
    int reminderHour = 9,
  }) async {
    if (!_ready) await init();
    final hour = reminderHour.clamp(0, 23);
    final days = (reminderDays != null && reminderDays.isNotEmpty)
        ? List<int>.from(reminderDays)
        : <int>[
            if (sameDay) 0,
            if (dayBefore) 1,
          ];
    // لغو بازهٔ وسیع روزهای قبل (۰..۳۰) برای جلوگیری از اعلان یتیم
    for (var i = 0; i < paymentDates.length; i++) {
      for (var d = 0; d <= 30; d++) {
        await cancel(loanNotifId(loanId, i, daysBefore: d));
      }
    }
    for (var i = 0; i < paymentDates.length; i++) {
      final day = paymentDates[i];
      for (final d in days) {
        final when = DateTime(day.year, day.month, day.day, hour, 0)
            .subtract(Duration(days: d));
        final remain = d == 0
            ? 'امروز موعد قسط ${i + 1} است'
            : d == 1
                ? 'فردا موعد قسط ${i + 1} است'
                : '$d روز تا قسط ${i + 1}';
        await schedule(
          id: loanNotifId(loanId, i, daysBefore: d),
          title: 'قسط: $title',
          body: '$remain · ${amount.round()} تومان',
          when: when,
          payload: 'loan:$loanId:$i',
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
