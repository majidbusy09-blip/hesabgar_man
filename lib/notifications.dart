import 'dart:io';

import 'package:flutter/foundation.dart';
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

      await _plugin.initialize(initSettings);

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
      // Android 13+
      await android?.requestNotificationsPermission();
      // Exact alarms when available
      try {
        await android?.requestExactAlarmsPermission();
      } catch (_) {}

      _ready = true;
    } catch (e) {
      debugPrint('AppNotifications.init: $e');
      _ready = false;
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) await init();
    if (!Platform.isAndroid) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ok = await android?.requestNotificationsPermission();
    return ok ?? false;
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

  /// زمان‌بندی یک اعلان در [when] محلی
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_ready) await init();
    if (!_ready) return;
    if (when.isBefore(DateTime.now().add(const Duration(seconds: 30)))) {
      return; // گذشته یا خیلی نزدیک
    }
    try {
      final tzWhen = tz.TZDateTime.from(when, tz.local);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('schedule($id): $e');
      // fallback inexact
      try {
        final tzWhen = tz.TZDateTime.from(when, tz.local);
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzWhen,
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e2) {
        debugPrint('schedule fallback: $e2');
      }
    }
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
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

  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime start,
    required int reminderMinutes,
  }) async {
    if (reminderMinutes <= 0) {
      await cancel(eventNotifId(eventId));
      return;
    }
    final when = start.subtract(Duration(minutes: reminderMinutes));
    await schedule(
      id: eventNotifId(eventId),
      title: 'یادآوری: $title',
      body: reminderMinutes >= 1440
          ? 'فردا: $title'
          : 'به‌زودی: $title',
      when: when,
    );
  }
}
