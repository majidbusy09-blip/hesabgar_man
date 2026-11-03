// تقویم ۲.۰ — رویداد، یادداشت، تسک، ابزارها (متصل به Jalali موجود)
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'notifications.dart';
import 'features.dart'
    show Jalali, HijriDate, OccasionData, showJalaliDatePicker, FinanceScreen,
        DateConverterSheet;

// ─── مدل‌ها ───
class CalCategory {
  final String id;
  final String name;
  final int colorValue;
  final bool archived;
  const CalCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    this.archived = false,
  });
  Color get color => Color(colorValue);
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': colorValue,
        'archived': archived,
      };
  factory CalCategory.fromJson(Map<String, dynamic> j) => CalCategory(
        id: j['id'] as String,
        name: j['name'] as String,
        colorValue: (j['color'] as num?)?.toInt() ?? 0xFF42A5F5,
        archived: j['archived'] as bool? ?? false,
      );
  static List<CalCategory> defaults = [
    CalCategory(id: 'c_personal', name: 'شخصی', colorValue: 0xFF42A5F5),
    CalCategory(id: 'c_family', name: 'خانواده', colorValue: 0xFF66BB6A),
    CalCategory(id: 'c_work', name: 'کار', colorValue: 0xFFEF5350),
    CalCategory(id: 'c_study', name: 'تحصیل', colorValue: 0xFFAB47BC),
    CalCategory(id: 'c_health', name: 'سلامت', colorValue: 0xFF26A69A),
    CalCategory(id: 'c_finance', name: 'مالی', colorValue: 0xFFFFA726),
    CalCategory(id: 'c_other', name: 'سایر', colorValue: 0xFF78909C),
  ];
}

class CalEvent {
  final String id;
  final String title;
  final String? note;
  final DateTime start; // محلی
  final DateTime? end;
  final bool allDay;
  final String categoryId;
  final int colorValue;
  final String? recurrence; // none|daily|weekly|monthly|yearly
  final DateTime? recurrenceUntil;
  final int reminderMinutes; // 0=off, 15, 60, 1440
  final bool done;

  CalEvent({
    required this.id,
    required this.title,
    this.note,
    required this.start,
    this.end,
    this.allDay = false,
    this.categoryId = 'c_personal',
    this.colorValue = 0xFF42A5F5,
    this.recurrence = 'none',
    this.recurrenceUntil,
    this.reminderMinutes = 0,
    this.done = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'allDay': allDay,
        'categoryId': categoryId,
        'color': colorValue,
        'recurrence': recurrence,
        'recurrenceUntil': recurrenceUntil?.toIso8601String(),
        'reminderMinutes': reminderMinutes,
        'done': done,
      };

  factory CalEvent.fromJson(Map<String, dynamic> j) => CalEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        note: j['note'] as String?,
        start: DateTime.tryParse(j['start'] as String? ?? '') ?? DateTime.now(),
        end: j['end'] != null ? DateTime.tryParse(j['end'] as String) : null,
        allDay: j['allDay'] as bool? ?? false,
        categoryId: j['categoryId'] as String? ?? 'c_personal',
        colorValue: (j['color'] as num?)?.toInt() ?? 0xFF42A5F5,
        recurrence: j['recurrence'] as String? ?? 'none',
        recurrenceUntil: j['recurrenceUntil'] != null
            ? DateTime.tryParse(j['recurrenceUntil'] as String)
            : null,
        reminderMinutes: (j['reminderMinutes'] as num?)?.toInt() ?? 0,
        done: j['done'] as bool? ?? false,
      );

  CalEvent copyWith({
    String? title,
    String? note,
    DateTime? start,
    DateTime? end,
    bool? allDay,
    String? categoryId,
    int? colorValue,
    String? recurrence,
    DateTime? recurrenceUntil,
    int? reminderMinutes,
    bool? done,
  }) =>
      CalEvent(
        id: id,
        title: title ?? this.title,
        note: note ?? this.note,
        start: start ?? this.start,
        end: end ?? this.end,
        allDay: allDay ?? this.allDay,
        categoryId: categoryId ?? this.categoryId,
        colorValue: colorValue ?? this.colorValue,
        recurrence: recurrence ?? this.recurrence,
        recurrenceUntil: recurrenceUntil ?? this.recurrenceUntil,
        reminderMinutes: reminderMinutes ?? this.reminderMinutes,
        done: done ?? this.done,
      );
}

class CalNote {
  final String id;
  final String title;
  final String body;
  final DateTime? day; // null = بدون تاریخ
  final int colorValue;
  CalNote({
    required this.id,
    required this.title,
    required this.body,
    this.day,
    this.colorValue = 0xFFFFF59D,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'day': day?.toIso8601String(),
        'color': colorValue,
      };
  factory CalNote.fromJson(Map<String, dynamic> j) => CalNote(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        day: j['day'] != null ? DateTime.tryParse(j['day'] as String) : null,
        colorValue: (j['color'] as num?)?.toInt() ?? 0xFFFFF59D,
      );
}

class CalTask {
  final String id;
  final String title;
  final String? note;
  final DateTime due;
  final int priority; // 0 low 1 med 2 high
  final String categoryId;
  final bool done;
  CalTask({
    required this.id,
    required this.title,
    this.note,
    required this.due,
    this.priority = 1,
    this.categoryId = 'c_personal',
    this.done = false,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'due': due.toIso8601String(),
        'priority': priority,
        'categoryId': categoryId,
        'done': done,
      };
  factory CalTask.fromJson(Map<String, dynamic> j) => CalTask(
        id: j['id'] as String,
        title: j['title'] as String,
        note: j['note'] as String?,
        due: DateTime.tryParse(j['due'] as String? ?? '') ?? DateTime.now(),
        priority: (j['priority'] as num?)?.toInt() ?? 1,
        categoryId: j['categoryId'] as String? ?? 'c_personal',
        done: j['done'] as bool? ?? false,
      );
  CalTask copyWith({bool? done, String? title}) => CalTask(
        id: id,
        title: title ?? this.title,
        note: note,
        due: due,
        priority: priority,
        categoryId: categoryId,
        done: done ?? this.done,
      );
}

class PersonalOccasion {
  final String id;
  final String title;
  final int month; // جلالی
  final int day;
  final int remindDaysBefore;
  PersonalOccasion({
    required this.id,
    required this.title,
    required this.month,
    required this.day,
    this.remindDaysBefore = 1,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'month': month,
        'day': day,
        'remindDaysBefore': remindDaysBefore,
      };
  factory PersonalOccasion.fromJson(Map<String, dynamic> j) =>
      PersonalOccasion(
        id: j['id'] as String,
        title: j['title'] as String,
        month: (j['month'] as num).toInt(),
        day: (j['day'] as num).toInt(),
        remindDaysBefore: (j['remindDaysBefore'] as num?)?.toInt() ?? 1,
      );
}

class CalSettings {
  String defaultView; // month|week|day|agenda
  bool showOccasions;
  bool showHolidays;
  String prayerCity;
  double cityLat;
  double cityLng;
  CalSettings({
    this.defaultView = 'month',
    this.showOccasions = true,
    this.showHolidays = true,
    this.prayerCity = 'تهران',
    this.cityLat = 35.6892,
    this.cityLng = 51.3890,
  });
  Map<String, dynamic> toJson() => {
        'defaultView': defaultView,
        'showOccasions': showOccasions,
        'showHolidays': showHolidays,
        'prayerCity': prayerCity,
        'cityLat': cityLat,
        'cityLng': cityLng,
      };
  factory CalSettings.fromJson(Map<String, dynamic>? j) {
    if (j == null) return CalSettings();
    return CalSettings(
      defaultView: j['defaultView'] as String? ?? 'month',
      showOccasions: j['showOccasions'] as bool? ?? true,
      showHolidays: j['showHolidays'] as bool? ?? true,
      prayerCity: j['prayerCity'] as String? ?? 'تهران',
      cityLat: (j['cityLat'] as num?)?.toDouble() ?? 35.6892,
      cityLng: (j['cityLng'] as num?)?.toDouble() ?? 51.3890,
    );
  }
}

class DhikrState {
  String name;
  int count;
  int target;
  DhikrState({this.name = 'سبحان‌الله', this.count = 0, this.target = 33});
  Map<String, dynamic> toJson() =>
      {'name': name, 'count': count, 'target': target};
  factory DhikrState.fromJson(Map<String, dynamic>? j) => DhikrState(
        name: j?['name'] as String? ?? 'سبحان‌الله',
        count: (j?['count'] as num?)?.toInt() ?? 0,
        target: (j?['target'] as num?)?.toInt() ?? 33,
      );
}

// ─── Store ───
class CalendarStore {
  static const _kEvents = 'cal_events_v1';
  static const _kNotes = 'cal_notes_v1';
  static const _kTasks = 'cal_tasks_v1';
  static const _kCats = 'cal_cats_v1';
  static const _kOcc = 'cal_personal_occ_v1';
  static const _kSettings = 'cal_settings_v1';
  static const _kDhikr = 'cal_dhikr_v1';

  /// نمونهٔ مشترک تا تسهیلات و صفحهٔ تقویم یک داده ببینند
  static final CalendarStore instance = CalendarStore._();
  factory CalendarStore() => instance;
  CalendarStore._();

  List<CalEvent> events = [];
  List<CalNote> notes = [];
  List<CalTask> tasks = [];
  List<CalCategory> categories = List.from(CalCategory.defaults);
  List<PersonalOccasion> personalOccasions = [];
  CalSettings settings = CalSettings();
  DhikrState dhikr = DhikrState();
  String? lastError;

  /// برای نوسازی UI تقویم بعد از تغییر از بخش‌های دیگر
  final ValueNotifier<int> revision = ValueNotifier<int>(0);
  void _bump() => revision.value++;

  Future<void> load() async {
    lastError = null;
    try {
      final s = await LocalStore.instance;
      events = _decodeList(s.getString(_kEvents), (m) => CalEvent.fromJson(m));
      notes = _decodeList(s.getString(_kNotes), (m) => CalNote.fromJson(m));
      tasks = _decodeList(s.getString(_kTasks), (m) => CalTask.fromJson(m));
      final cats =
          _decodeList(s.getString(_kCats), (m) => CalCategory.fromJson(m));
      if (cats.isNotEmpty) {
        categories = cats;
        final ids = categories.map((c) => c.id).toSet();
        for (final d in CalCategory.defaults) {
          if (!ids.contains(d.id)) categories.add(d);
        }
      }
      personalOccasions =
          _decodeList(s.getString(_kOcc), (m) => PersonalOccasion.fromJson(m));
      final rawS = s.getString(_kSettings);
      if (rawS != null && rawS.isNotEmpty) {
        settings = CalSettings.fromJson(jsonDecode(rawS) as Map<String, dynamic>);
      }
      final rawD = s.getString(_kDhikr);
      if (rawD != null && rawD.isNotEmpty) {
        dhikr = DhikrState.fromJson(jsonDecode(rawD) as Map<String, dynamic>);
      }
    } catch (e) {
      lastError = e.toString();
      rethrow;
    }
  }

  List<T> _decodeList<T>(
      String? raw, T Function(Map<String, dynamic>) f) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) {
            try {
              return f(e as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<T>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(String key, List list) async {
    final s = await LocalStore.instance;
    await s.setString(
        key, jsonEncode(list.map((e) => (e as dynamic).toJson()).toList()));
  }

  Future<void> upsertEvent(CalEvent e) async {
    final i = events.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      events[i] = e;
    } else {
      events.add(e);
    }
    await _save(_kEvents, events);
    _bump();
  }

  Future<void> removeEvent(String id) async {
    events.removeWhere((e) => e.id == id);
    await _save(_kEvents, events);
    _bump();
  }

  /// حذف چند رویداد و افزودن دسته‌ای با یک بار ذخیره (برای اقساط وام)
  Future<void> replaceEventsByIdPrefix(String prefix, List<CalEvent> next) async {
    events.removeWhere((e) => e.id.startsWith(prefix) || e.id.contains(prefix));
    events.addAll(next);
    await _save(_kEvents, events);
    _bump();
  }

  Future<void> upsertNote(CalNote n) async {
    final i = notes.indexWhere((x) => x.id == n.id);
    if (i >= 0) {
      notes[i] = n;
    } else {
      notes.add(n);
    }
    await _save(_kNotes, notes);
  }

  Future<void> removeNote(String id) async {
    notes.removeWhere((e) => e.id == id);
    await _save(_kNotes, notes);
  }

  Future<void> upsertTask(CalTask t) async {
    final i = tasks.indexWhere((x) => x.id == t.id);
    if (i >= 0) {
      tasks[i] = t;
    } else {
      tasks.add(t);
    }
    await _save(_kTasks, tasks);
  }

  Future<void> removeTask(String id) async {
    tasks.removeWhere((e) => e.id == id);
    await _save(_kTasks, tasks);
  }

  Future<void> upsertPersonal(PersonalOccasion o) async {
    final i = personalOccasions.indexWhere((x) => x.id == o.id);
    if (i >= 0) {
      personalOccasions[i] = o;
    } else {
      personalOccasions.add(o);
    }
    await _save(_kOcc, personalOccasions);
  }

  Future<void> removePersonal(String id) async {
    personalOccasions.removeWhere((e) => e.id == id);
    await _save(_kOcc, personalOccasions);
  }

  Future<void> saveSettings() async {
    final s = await LocalStore.instance;
    await s.setString(_kSettings, jsonEncode(settings.toJson()));
  }

  Future<void> saveDhikr() async {
    final s = await LocalStore.instance;
    await s.setString(_kDhikr, jsonEncode(dhikr.toJson()));
  }

  static DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

  /// نمونه‌های رخداد با تکرار ساده برای یک بازه
  List<CalEvent> occurrencesOn(DateTime day) {
    final d0 = _d(day);
    final out = <CalEvent>[];
    for (final e in events) {
      if (e.recurrence == null || e.recurrence == 'none') {
        if (_d(e.start) == d0) out.add(e);
        continue;
      }
      var cursor = _d(e.start);
      final until = e.recurrenceUntil != null
          ? _d(e.recurrenceUntil!)
          : d0.add(const Duration(days: 1));
      var guard = 0;
      while (!cursor.isAfter(d0) && guard < 400) {
        guard++;
        if (cursor == d0 && !cursor.isAfter(until)) {
          out.add(e.copyWith(start: DateTime(
            d0.year,
            d0.month,
            d0.day,
            e.start.hour,
            e.start.minute,
          )));
          break;
        }
        if (cursor.isAfter(until)) break;
        switch (e.recurrence) {
          case 'daily':
            cursor = cursor.add(const Duration(days: 1));
            break;
          case 'weekly':
            cursor = cursor.add(const Duration(days: 7));
            break;
          case 'monthly':
            final m = cursor.month + 1;
            final y = cursor.year + (m > 12 ? 1 : 0);
            final mm = m > 12 ? 1 : m;
            final last = DateTime(y, mm + 1, 0).day;
            cursor = DateTime(y, mm, cursor.day.clamp(1, last));
            break;
          case 'yearly':
            cursor = DateTime(cursor.year + 1, cursor.month, cursor.day);
            break;
          default:
            guard = 999;
        }
      }
    }
    return out;
  }

  List<CalNote> notesOn(DateTime day) {
    final d0 = _d(day);
    return notes.where((n) => n.day != null && _d(n.day!) == d0).toList();
  }

  List<CalTask> tasksOn(DateTime day) {
    final d0 = _d(day);
    return tasks.where((t) => _d(t.due) == d0).toList();
  }

  bool hasMarker(DateTime day) {
    if (occurrencesOn(day).isNotEmpty) return true;
    if (notesOn(day).isNotEmpty) return true;
    if (tasksOn(day).isNotEmpty) return true;
    final j = Jalali.fromDateTime(day);
    if (personalOccasions.any((o) => o.month == j.month && o.day == j.day)) {
      return true;
    }
    return false;
  }
}

// ─── اوقات شرعی (تقریبی — مرجع رسمی نیست) ───
class PrayerTimesApprox {
  /// آفست ساعت ایران نسبت به UTC (ثابت؛ بدون تغییر ساعت تابستانی فعلی)
  static const double iranOffsetHours = 3.5;

  /// اوقات شرعی تقریبی بر اساس مختصات و روز — برای ایران با UTC+3:30
  static Map<String, TimeOfDay> compute(DateTime date, double lat, double lng,
      {double? utcOffsetHours}) {
    final tz = utcOffsetHours ?? iranOffsetHours;
    final day = date.difference(DateTime(date.year, 1, 1)).inDays + 1.0;
    final gamma = 2 * math.pi / 365 * (day - 1 + 0.5);
    // معادله زمان (دقیقه)
    final eqTime = 229.18 *
        (0.000075 +
            0.001868 * math.cos(gamma) -
            0.032077 * math.sin(gamma) -
            0.014615 * math.cos(2 * gamma) -
            0.040849 * math.sin(2 * gamma));
    // میل خورشید (رادیان)
    final decl = 0.006918 -
        0.399912 * math.cos(gamma) +
        0.070257 * math.sin(gamma) -
        0.006758 * math.cos(2 * gamma) +
        0.000907 * math.sin(2 * gamma) -
        0.002697 * math.cos(3 * gamma) +
        0.00148 * math.sin(3 * gamma);
    final latR = lat * math.pi / 180;

    double hourAngle(double angleDeg) {
      final a = angleDeg * math.pi / 180;
      final cosH = (math.sin(a) - math.sin(latR) * math.sin(decl)) /
          (math.cos(latR) * math.cos(decl));
      if (cosH.abs() > 1.0) {
        // قطبی / غیرقابل‌محاسبه
        return 6.0;
      }
      return math.acos(cosH.clamp(-1.0, 1.0)) * 180 / math.pi / 15.0;
    }

    // ظهر شرعی به وقت محلی: 12 + (منطقه زمانی − طول جغرافیایی/۱۵) − معادله زمان
    final solarNoon = 12.0 + tz - lng / 15.0 - eqTime / 60.0;

    // زوایا (درجه): صبح ۱۸−، طلوع ۰.۸۳۳−، عشا ۱۷− (تقریب رایج)
    final haRise = hourAngle(-0.833);
    final haFajr = hourAngle(-18.0);
    final haIsha = hourAngle(-17.5);
    // عصر (شافعی): سایه = طول شیء + سایه ظهر
    final cosZenithAsr = math.sin(latR) * math.sin(decl) +
        math.cos(latR) * math.cos(decl);
    final zenithAsr = math.acos(cosZenithAsr.clamp(-1.0, 1.0));
    final shadow = 1.0 + math.tan(zenithAsr.abs());
    final altAsr = math.atan(1.0 / shadow);
    final haAsr = hourAngle(altAsr * 180 / math.pi);

    TimeOfDay td(double h) {
      var x = h % 24;
      if (x < 0) x += 24;
      final hh = x.floor();
      final mm = ((x - hh) * 60).round();
      if (mm >= 60) return TimeOfDay(hour: (hh + 1) % 24, minute: 0);
      return TimeOfDay(hour: hh, minute: mm.clamp(0, 59));
    }

    final sunrise = solarNoon - haRise;
    final sunset = solarNoon + haRise;
    // مغرب: چند دقیقه بعد از غروب (تقریباً ۳–۴ دقیقه برای ایران)
    final maghrib = sunset + 4 / 60.0;
    // نیمه‌شب شرعی: وسط غروب تا طلوع فردا
    final nightLen = (sunrise + 24) - sunset;
    final midnight = (sunset + nightLen / 2) % 24;

    return {
      'اذان صبح': td(solarNoon - haFajr),
      'طلوع آفتاب': td(sunrise),
      'اذان ظهر': td(solarNoon),
      'اذان عصر': td(solarNoon + haAsr),
      'غروب آفتاب': td(sunset),
      'اذان مغرب': td(maghrib),
      'اذان عشا': td(solarNoon + haIsha),
      'نیمه‌شب شرعی': td(midnight),
    };
  }

  static String fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// زاویه قبله از شمال جغرافیایی (درجه، ۰–۳۶۰)
  static double qiblaBearing(double lat, double lng) {
    const kLat = 21.422487 * math.pi / 180;
    const kLng = 39.826206 * math.pi / 180;
    final latR = lat * math.pi / 180;
    final dLng = kLng - lng * math.pi / 180;
    final x = math.sin(dLng);
    final y =
        math.cos(latR) * math.tan(kLat) - math.sin(latR) * math.cos(dLng);
    var br = math.atan2(x, y) * 180 / math.pi;
    br = (br + 360) % 360;
    return br;
  }
}

/// رنگ فصل شمسی برای تم تقویم
class SeasonTheme {
  final String name;
  final Color primary;
  final Color soft;
  final Color accent;
  const SeasonTheme(this.name, this.primary, this.soft, this.accent);

  static SeasonTheme ofJalali(Jalali j) {
    // بهار ۱–۳، تابستان ۴–۶، پاییز ۷–۹، زمستان ۱۰–۱۲
    switch ((j.month - 1) ~/ 3) {
      case 0:
        return const SeasonTheme(
          'بهار',
          Color(0xFF2E7D32),
          Color(0xFFC8E6C9),
          Color(0xFF66BB6A),
        );
      case 1:
        return const SeasonTheme(
          'تابستان',
          Color(0xFFEF6C00),
          Color(0xFFFFE0B2),
          Color(0xFFFFA726),
        );
      case 2:
        return const SeasonTheme(
          'پاییز',
          Color(0xFFBF360C),
          Color(0xFFFFCCBC),
          Color(0xFFFF7043),
        );
      default:
        return const SeasonTheme(
          'زمستان',
          Color(0xFF1565C0),
          Color(0xFFBBDEFB),
          Color(0xFF42A5F5),
        );
    }
  }
}

/// ادعیه و اذکار آماده
class DuaCatalog {
  static const items = <Map<String, String>>[
    {
      'title': 'ذکر صبح',
      'ar': 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ',
      'fa': 'صبح کردیم و فرمانروایی از آنِ خداست.',
    },
    {
      'title': 'ذکر شب',
      'ar': 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ',
      'fa': 'شب کردیم و فرمانروایی از آنِ خداست.',
    },
    {
      'title': 'قبل از غذا',
      'ar': 'بِسْمِ اللَّهِ',
      'fa': 'به نام خداوند.',
    },
    {
      'title': 'بعد از غذا',
      'ar': 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا',
      'fa': 'ستایش خدایی را که به ما خوراک و نوشیدنی داد.',
    },
    {
      'title': 'خروج از خانه',
      'ar': 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ',
      'fa': 'به نام خدا، بر خدا توکل کردم.',
    },
    {
      'title': 'ورود به خانه',
      'ar': 'بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا',
      'fa': 'به نام خدا وارد شدیم و به نام خدا بیرون آمدیم.',
    },
    {
      'title': 'سفر',
      'ar': 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا',
      'fa': 'پاک است آن‌که این را برای ما رام کرد.',
    },
    {
      'title': 'آیه الکرسی (آغاز)',
      'ar': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
      'fa': 'خداوند یکتاست؛ زنده و پاینده است.',
    },
    {
      'title': 'طلب آمرزش',
      'ar': 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
      'fa': 'از خدا آمرزش می‌خواهم و به سوی او بازمی‌گردم.',
    },
    {
      'title': 'صلوات',
      'ar': 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَآلِ مُحَمَّدٍ',
      'fa': 'خدایا بر محمد و خاندان محمد درود فرست.',
    },
    {
      'title': 'رفع غم',
      'ar': 'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      'fa': 'معبودی جز تو نیست؛ من از ستمکاران بودم. (ذکر یونس)',
    },
    {
      'title': 'سلامتی',
      'ar': 'اللَّهُمَّ عَافِنِي فِي بَدَنِي',
      'fa': 'خدایا بدنم را عافیت ده.',
    },
    {
      'title': 'رزق',
      'ar': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ رِزْقًا طَيِّبًا',
      'fa': 'خدایا از تو روزی پاک می‌خواهم.',
    },
    {
      'title': 'خواب',
      'ar': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      'fa': 'به نام تو می‌میرم و زنده می‌شوم.',
    },
    {
      'title': 'بیداری',
      'ar': 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا',
      'fa': 'ستایش خدایی را که پس از خواب ما را زنده کرد.',
    },
  ];

  static const dhikrPresets = <Map<String, dynamic>>[
    {'name': 'سبحان‌الله', 'target': 33},
    {'name': 'الحمدلله', 'target': 33},
    {'name': 'الله‌اکبر', 'target': 34},
    {'name': 'لا اله‌الا الله', 'target': 100},
    {'name': 'صلوات', 'target': 100},
    {'name': 'استغفرالله', 'target': 100},
    {'name': 'یا لطیف', 'target': 129},
    {'name': 'حسبی الله', 'target': 7},
  ];
}

// ─── UI اصلی ───
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  final _store = CalendarStore();
  bool _loading = true;
  String? _error;
  late Jalali _focused;
  late Jalali _todayJ;
  DateTime? _selectedG;
  late String _view; // month week day agenda
  late TabController _toolsTab; // unused placeholder

  static const _cities = <String, List<double>>{
    'تهران': [35.6892, 51.3890],
    'مشهد': [36.2972, 59.6067],
    'اصفهان': [32.6546, 51.6680],
    'شیراز': [29.5918, 52.5837],
    'تبریز': [38.0962, 46.2738],
    'قم': [34.6416, 50.8746],
    'اهواز': [31.3183, 48.6706],
    'کرج': [35.8400, 50.9391],
  };

  @override
  void initState() {
    super.initState();
    _todayJ = Jalali.fromDateTime(DateTime.now());
    _focused = Jalali(_todayJ.year, _todayJ.month, 1);
    _selectedG = DateTime.now();
    _view = 'month';
    _toolsTab = TabController(length: 1, vsync: this);
    _store.revision.addListener(_onStoreRevision);
    _load();
  }

  void _onStoreRevision() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.revision.removeListener(_onStoreRevision);
    _toolsTab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _store.load();
      _view = _store.settings.defaultView;
    } catch (e) {
      _error = 'خطا در بارگذاری تقویم؛ داده پاک نشده است.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Jalali get _selectedJ => Jalali.fromDateTime(_selectedG ?? DateTime.now());
  HijriDate get _selectedH =>
      HijriDate.fromGregorian(_selectedG ?? DateTime.now());

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _selectedG = now;
      final j = Jalali.fromDateTime(now);
      _focused = Jalali(j.year, j.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final season = SeasonTheme.ofJalali(_focused);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تقویم')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقویم',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'مبدل تاریخ',
            onPressed: _openDateConverter,
            icon: const Icon(Icons.compare_arrows_rounded),
          ),
          IconButton(
            tooltip: 'امروز',
            onPressed: _goToday,
            icon: const Icon(Icons.today_rounded),
          ),
          IconButton(
            tooltip: 'ابزارها',
            onPressed: _openTools,
            icon: const Icon(Icons.grid_view_rounded),
          ),
          IconButton(
            tooltip: 'تنظیمات',
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddMenu(),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          if (_error != null)
            Material(
              color: scheme.errorContainer,
              child: ListTile(
                dense: true,
                title: Text(_error!,
                    style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                trailing: TextButton(
                    onPressed: _load,
                    child: const Text('تلاش',
                        style: TextStyle(fontFamily: 'Vazirmatn'))),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SegmentedButton<String>(
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                        value: 'month',
                        label: Text('ماه',
                            style: TextStyle(
                                fontFamily: 'Vazirmatn', fontSize: 12))),
                    ButtonSegment(
                        value: 'week',
                        label: Text('هفته',
                            style: TextStyle(
                                fontFamily: 'Vazirmatn', fontSize: 12))),
                    ButtonSegment(
                        value: 'day',
                        label: Text('روز',
                            style: TextStyle(
                                fontFamily: 'Vazirmatn', fontSize: 12))),
                    ButtonSegment(
                        value: 'agenda',
                        label: Text('فهرست',
                            style: TextStyle(
                                fontFamily: 'Vazirmatn', fontSize: 12))),
                  ],
                  selected: {_view},
                  onSelectionChanged: (s) => setState(() => _view = s.first),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(scheme)),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    switch (_view) {
      case 'week':
        return _buildWeek(scheme);
      case 'day':
        return _buildDay(scheme);
      case 'agenda':
        return _buildAgenda(scheme);
      default:
        return _buildMonth(scheme);
    }
  }

  Widget _buildMonth(ColorScheme scheme) {
    final season = SeasonTheme.ofJalali(_focused);
    final first = Jalali(_focused.year, _focused.month, 1);
    final len = first.monthLength;
    final g0 = first.toDateTime();
    final lead = g0.weekday == 6
        ? 0
        : g0.weekday == 7
            ? 1
            : g0.weekday + 1;
    final sel = _selectedG ?? DateTime.now();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: () =>
                    setState(() => _focused = _focused.addMonths(-1)),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _focused.monthName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: season.primary,
                      ),
                    ),
                    Text(
                      '${_focused.year} · ${season.name}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: season.accent,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () =>
                    setState(() => _focused = _focused.addMonths(1)),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: Row(
            children: [
              for (var wi = 0; wi < Jalali.weekDays.length; wi++)
                Expanded(
                  child: Text(
                    Jalali.weekDays[wi].substring(0, 1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: wi == 6
                          ? scheme.error.withValues(alpha: 0.85)
                          : scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.92,
              ),
              itemCount: lead + len,
              itemBuilder: (_, i) {
                if (i < lead) return const SizedBox.shrink();
                final day = i - lead + 1;
                final j = Jalali(_focused.year, _focused.month, day);
                final g = j.toDateTime();
                final isToday = j.year == _todayJ.year &&
                    j.month == _todayJ.month &&
                    j.day == _todayJ.day;
                final isSel = g.year == sel.year &&
                    g.month == sel.month &&
                    g.day == sel.day;
                final occasions = [
                  if (_store.settings.showOccasions)
                    ...OccasionData.forDay(
                        system: 'jalali', month: j.month, day: j.day),
                ];
                final holiday = _store.settings.showHolidays &&
                    (occasions.any((o) => o.isHoliday) ||
                        j.weekdayIndex == 6);
                final hasEv = _store.occurrencesOn(g).isNotEmpty;
                final hasNote = _store.notesOn(g).isNotEmpty;
                final hasTask = _store.tasksOn(g).isNotEmpty;
                final hasPers = _store.personalOccasions.any(
                    (o) => o.month == j.month && o.day == j.day);
                final hasMark = hasEv || hasNote || hasTask || hasPers;

                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: Material(
                    color: isSel
                        ? scheme.primary
                        : (isToday
                            ? scheme.primaryContainer.withValues(alpha: 0.65)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedG = g),
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          if (isToday && !isSel)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: scheme.primary,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 15,
                                fontWeight: isSel || isToday
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isSel
                                    ? scheme.onPrimary
                                    : (holiday
                                        ? scheme.error
                                        : scheme.onSurface),
                              ),
                            ),
                          ),
                          if (hasMark)
                            Positioned(
                              bottom: 5,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasEv)
                                    _dot(isSel
                                        ? scheme.onPrimary
                                        : scheme.primary),
                                  if (hasTask)
                                    _dot(isSel
                                        ? scheme.onPrimary
                                            .withValues(alpha: 0.85)
                                        : scheme.tertiary),
                                  if (hasNote || hasPers)
                                    _dot(isSel
                                        ? scheme.onPrimary
                                            .withValues(alpha: 0.7)
                                        : scheme.secondary),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        Expanded(flex: 4, child: _dayPanel(scheme)),
      ],
    );
  }

  Widget _dot(Color c) => Container(
        width: 5,
        height: 5,
        margin: const EdgeInsets.symmetric(horizontal: 1.2),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  Widget _dayPanel(ColorScheme scheme) {
    final g = _selectedG ?? DateTime.now();
    final j = Jalali.fromDateTime(g);
    final h = HijriDate.fromGregorian(g);
    final evs = _store.occurrencesOn(g);
    final nts = _store.notesOn(g);
    final tks = _store.tasksOn(g);
    final occ = [
      ...OccasionData.forDay(system: 'jalali', month: j.month, day: j.day),
      ...OccasionData.forDay(system: 'gregorian', month: g.month, day: g.day),
      ...OccasionData.forDay(system: 'hijri', month: h.month, day: h.day),
    ];
    final personal = _store.personalOccasions
        .where((o) => o.month == j.month && o.day == j.day)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 88),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${Jalali.weekDays[j.weekdayIndex]} ${j.day} ${j.monthName}',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'شمسی ${j.year}  ·  میلادی ${g.day}/${g.month}/${g.year}  ·  قمری ${h.day} ${HijriDate.monthNames[h.month - 1]}',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11.5,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (occ.isNotEmpty || personal.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final o in occ)
                Chip(
                  label: Text(o.title,
                      style: const TextStyle(
                          fontFamily: 'Vazirmatn', fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: o.isHoliday
                      ? scheme.errorContainer
                      : scheme.surfaceContainerHighest,
                ),
              for (final o in personal)
                Chip(
                  label: Text(o.title,
                      style: const TextStyle(
                          fontFamily: 'Vazirmatn', fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.star, size: 14),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        if (evs.isEmpty && nts.isEmpty && tks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(Icons.event_available_outlined,
                    size: 36,
                    color: scheme.onSurface.withValues(alpha: 0.28)),
                const SizedBox(height: 8),
                Text(
                  'برای این روز برنامه‌ای نیست',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13.5,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  'با دکمه + رویداد، یادداشت یا تسک اضافه کنید',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              ],
            ),
          ),
        for (final e in evs)
          ListTile(
            dense: true,
            leading: CircleAvatar(
                radius: 6, backgroundColor: Color(e.colorValue)),
            title: Text(e.title,
                style: const TextStyle(fontFamily: 'Vazirmatn')),
            subtitle: Text(
              e.allDay
                  ? 'تمام‌روز'
                  : '${e.start.hour.toString().padLeft(2, '0')}:${e.start.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
            ),
            onTap: () => _editEvent(e),
          ),
        for (final n in nts)
          ListTile(
            dense: true,
            leading: const Icon(Icons.sticky_note_2_outlined, size: 20),
            title: Text(n.title.isEmpty ? 'یادداشت' : n.title,
                style: const TextStyle(fontFamily: 'Vazirmatn')),
            onTap: () => _editNote(n),
          ),
        for (final t in tks)
          CheckboxListTile(
            dense: true,
            value: t.done,
            onChanged: (v) async {
              await _store.upsertTask(t.copyWith(done: v ?? false));
              setState(() {});
            },
            title: Text(t.title,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  decoration: t.done ? TextDecoration.lineThrough : null,
                )),
          ),
      ],
    );
  }

  Widget _buildWeek(ColorScheme scheme) {
    final base = _selectedG ?? DateTime.now();
    // شروع هفته از شنبه
    final wd = base.weekday; // mon=1 .. sun=7
    final back = wd == 6 ? 0 : (wd == 7 ? 1 : wd + 1);
    final start = DateTime(base.year, base.month, base.day)
        .subtract(Duration(days: back));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'هفته قبل',
                onPressed: () => setState(() {
                  _selectedG = base.subtract(const Duration(days: 7));
                }),
                icon: const Icon(Icons.chevron_right),
              ),
              Expanded(
                child: Text(
                  'هفته ${Jalali.fromDateTime(start).day} ${Jalali.fromDateTime(start).monthName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'هفته بعد',
                onPressed: () => setState(() {
                  _selectedG = base.add(const Duration(days: 7));
                }),
                icon: const Icon(Icons.chevron_left),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
            itemCount: 7,
            itemBuilder: (_, i) {
              final day = start.add(Duration(days: i));
              final j = Jalali.fromDateTime(day);
              final isToday = j.year == _todayJ.year &&
                  j.month == _todayJ.month &&
                  j.day == _todayJ.day;
              final isSel = _selectedG != null &&
                  day.year == _selectedG!.year &&
                  day.month == _selectedG!.month &&
                  day.day == _selectedG!.day;
              final evs = _store.occurrencesOn(day);
              final tks = _store.tasksOn(day);
              final nts = _store.notesOn(day);
              final personal = _store.personalOccasions
                  .where((o) => o.month == j.month && o.day == j.day)
                  .toList();
              final occ = _store.settings.showOccasions
                  ? OccasionData.forDay(
                      system: 'jalali', month: j.month, day: j.day)
                  : <dynamic>[];
              final holiday = _store.settings.showHolidays &&
                  (occ.any((o) => o.isHoliday) || j.weekdayIndex == 6);

              return Card(
                elevation: 0,
                color: isSel
                    ? scheme.primaryContainer.withValues(alpha: 0.45)
                    : (isToday
                        ? scheme.secondaryContainer.withValues(alpha: 0.3)
                        : scheme.surfaceContainerHighest.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: holiday
                      ? BorderSide(color: scheme.error.withValues(alpha: 0.35))
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() {
                    _selectedG = day;
                    _view = 'day';
                  }),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${Jalali.weekDays[j.weekdayIndex]} ${j.day}',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.w800,
                                color: holiday ? scheme.error : null,
                              ),
                            ),
                            const Spacer(),
                            if (evs.isNotEmpty)
                              _miniBadge(scheme, '${evs.length} رویداد'),
                            if (tks.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _miniBadge(scheme, '${tks.length} تسک'),
                            ],
                          ],
                        ),
                        if (evs.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            evs.map((e) => e.title).take(3).join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12.5,
                              color: scheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                        if (personal.isNotEmpty || occ.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              [
                                ...personal.map((p) => p.title),
                                ...occ.map((o) => o.title),
                              ].take(2).join(' · '),
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11.5,
                                color: scheme.tertiary,
                              ),
                            ),
                          ),
                        if (evs.isEmpty &&
                            tks.isEmpty &&
                            nts.isEmpty &&
                            personal.isEmpty &&
                            occ.isEmpty)
                          Text(
                            'بدون برنامه',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              color: scheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _miniBadge(ColorScheme scheme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );
  }

  Widget _buildDay(ColorScheme scheme) => _dayPanel(scheme);

  Widget _buildAgenda(ColorScheme scheme) {
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day);
    final groups = <String, List<Map<String, dynamic>>>{};

    for (var i = 0; i < 90; i++) {
      final d = startDay.add(Duration(days: i));
      final j = Jalali.fromDateTime(d);
      final key = '${j.year}-${j.month}-${j.day}';
      final bucket = <Map<String, dynamic>>[];
      for (final e in _store.occurrencesOn(d)) {
        bucket.add({'type': 'event', 'd': d, 'e': e});
      }
      for (final t in _store.tasksOn(d).where((t) => !t.done)) {
        bucket.add({'type': 'task', 'd': d, 't': t});
      }
      for (final o in _store.personalOccasions
          .where((o) => o.month == j.month && o.day == j.day)) {
        bucket.add({'type': 'personal', 'd': d, 'o': o});
      }
      if (_store.settings.showOccasions) {
        for (final o in OccasionData.forDay(
            system: 'jalali', month: j.month, day: j.day)) {
          bucket.add({'type': 'occasion', 'd': d, 'occ': o});
        }
      }
      if (bucket.isNotEmpty) groups[key] = bucket;
    }

    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'در ۹۰ روز آینده رویدادی نیست.\nبا + رویداد، تسک یا مناسبت اضافه کنید.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      );
    }

    final keys = groups.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
      itemCount: keys.length,
      itemBuilder: (_, gi) {
        final items = groups[keys[gi]]!;
        final d = items.first['d'] as DateTime;
        final j = Jalali.fromDateTime(d);
        final isToday = j.year == _todayJ.year &&
            j.month == _todayJ.month &&
            j.day == _todayJ.day;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
              child: Text(
                isToday
                    ? 'امروز · ${j.day} ${j.monthName}'
                    : '${Jalali.weekDays[j.weekdayIndex]} ${j.day} ${j.monthName} ${j.year}',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.w800,
                  color: isToday ? scheme.primary : scheme.onSurface,
                ),
              ),
            ),
            for (final it in items)
              Card(
                elevation: 0,
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(
                    it['type'] == 'event'
                        ? Icons.event
                        : it['type'] == 'task'
                            ? Icons.check_circle_outline
                            : it['type'] == 'personal'
                                ? Icons.cake_outlined
                                : Icons.flag_outlined,
                    color: it['type'] == 'occasion'
                        ? scheme.error
                        : scheme.primary,
                  ),
                  title: Text(
                    it['type'] == 'event'
                        ? (it['e'] as CalEvent).title
                        : it['type'] == 'task'
                            ? (it['t'] as CalTask).title
                            : it['type'] == 'personal'
                                ? (it['o'] as PersonalOccasion).title
                                : (it['occ'] as dynamic).title as String,
                    style: const TextStyle(fontFamily: 'Vazirmatn'),
                  ),
                  subtitle: Text(
                    it['type'] == 'event'
                        ? ((it['e'] as CalEvent).allDay
                            ? 'تمام‌روز'
                            : '${(it['e'] as CalEvent).start.hour.toString().padLeft(2, '0')}:${(it['e'] as CalEvent).start.minute.toString().padLeft(2, '0')}')
                        : it['type'] == 'task'
                            ? 'تسک'
                            : it['type'] == 'personal'
                                ? 'مناسبت شخصی'
                                : 'مناسبت',
                    style: const TextStyle(
                        fontFamily: 'Vazirmatn', fontSize: 12),
                  ),
                  onTap: () {
                    if (it['type'] == 'event') {
                      _editEvent(it['e'] as CalEvent);
                    } else if (it['type'] == 'task') {
                      _editTask(it['t'] as CalTask);
                    } else {
                      setState(() {
                        _selectedG = d;
                        _view = 'day';
                      });
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _openAddMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('رویداد',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              onTap: () {
                Navigator.pop(ctx);
                _editEvent(null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: const Text('یادداشت',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              onTap: () {
                Navigator.pop(ctx);
                _editNote(null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('تسک',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              onTap: () {
                Navigator.pop(ctx);
                _editTask(null);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editEvent(CalEvent? existing) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final note = TextEditingController(text: existing?.note ?? '');
    var start = existing?.start ?? _selectedG ?? DateTime.now();
    var end = existing?.end ?? start.add(const Duration(hours: 1));
    var allDay = existing?.allDay ?? true;
    var recurrence = existing?.recurrence ?? 'none';
    var cat = existing?.categoryId ?? 'c_personal';
    var reminder = existing?.reminderMinutes ?? 0;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setL) {
          final j = Jalali.fromDateTime(start);
          return Padding(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(existing == null ? 'رویداد جدید' : 'ویرایش رویداد',
                      style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  TextField(
                      controller: title,
                      decoration: const InputDecoration(
                          labelText: 'عنوان',
                          labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                      style: const TextStyle(fontFamily: 'Vazirmatn')),
                  TextField(
                      controller: note,
                      decoration: const InputDecoration(
                          labelText: 'توضیح',
                          labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                      style: const TextStyle(fontFamily: 'Vazirmatn')),
                  SwitchListTile(
                    title: const Text('تمام‌روز',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    value: allDay,
                    onChanged: (v) => setL(() => allDay = v),
                  ),
                  if (!allDay) ...[
                    ListTile(
                      title: Text(
                        'ساعت شروع: ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontFamily: 'Vazirmatn'),
                      ),
                      trailing: TextButton(
                        child: const Text('تغییر',
                            style: TextStyle(fontFamily: 'Vazirmatn')),
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(start),
                          );
                          if (t != null) {
                            setL(() {
                              start = DateTime(start.year, start.month,
                                  start.day, t.hour, t.minute);
                              if (!end.isAfter(start)) {
                                end = start.add(const Duration(hours: 1));
                              }
                            });
                          }
                        },
                      ),
                    ),
                    ListTile(
                      title: Text(
                        'ساعت پایان: ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontFamily: 'Vazirmatn'),
                      ),
                      trailing: TextButton(
                        child: const Text('تغییر',
                            style: TextStyle(fontFamily: 'Vazirmatn')),
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(end),
                          );
                          if (t != null) {
                            setL(() {
                              end = DateTime(end.year, end.month, end.day,
                                  t.hour, t.minute);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                  ListTile(
                    title: Text(
                        '${j.day} ${j.monthName} ${j.year}',
                        style: const TextStyle(fontFamily: 'Vazirmatn')),
                    trailing: TextButton(
                      child: const Text('تاریخ',
                          style: TextStyle(fontFamily: 'Vazirmatn')),
                      onPressed: () async {
                        final p = await showJalaliDatePicker(
                            context: ctx, initial: j);
                        if (p != null) setL(() => start = p.toDateTime());
                      },
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: recurrence,
                    items: const [
                      DropdownMenuItem(
                          value: 'none',
                          child: Text('بدون تکرار',
                              style: TextStyle(fontFamily: 'Vazirmatn'))),
                      DropdownMenuItem(
                          value: 'daily',
                          child: Text('روزانه',
                              style: TextStyle(fontFamily: 'Vazirmatn'))),
                      DropdownMenuItem(
                          value: 'weekly',
                          child: Text('هفتگی',
                              style: TextStyle(fontFamily: 'Vazirmatn'))),
                      DropdownMenuItem(
                          value: 'monthly',
                          child: Text('ماهانه',
                              style: TextStyle(fontFamily: 'Vazirmatn'))),
                      DropdownMenuItem(
                          value: 'yearly',
                          child: Text('سالانه',
                              style: TextStyle(fontFamily: 'Vazirmatn'))),
                    ],
                    onChanged: (v) => setL(() => recurrence = v ?? 'none'),
                  ),
                  DropdownButtonFormField<int>(
                    value: reminder,
                    items: const [
                      DropdownMenuItem(
                          value: 0,
                          child: Text('بدون یادآوری',
                              style: TextStyle(fontFamily: 'Vazirmatn'))),
                      DropdownMenuItem(
                          value: 15,
                          child: Text('۱۵ دقیقه قبل',
                              style: TextStyle(fontFamily: 'Vazirmatn'))),
                      DropdownMenuItem(
                          value: 60,
                          child: Text('۱ ساعت قبل',
                              style: TextStyle(fontFamily: 'Vazirmatn'))),
                      DropdownMenuItem(
                          value: 1440,
                          child: Text('۱ روز قبل',
                              style: TextStyle(fontFamily: 'Vazirmatn'))),
                    ],
                    onChanged: (v) => setL(() => reminder = v ?? 0),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('ذخیره',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                  ),
                  if (existing != null)
                    TextButton(
                      onPressed: () async {
                        await _store.removeEvent(existing.id);
                        if (ctx.mounted) Navigator.pop(ctx, false);
                        setState(() {});
                      },
                      child: const Text('حذف',
                          style: TextStyle(
                              fontFamily: 'Vazirmatn', color: Colors.red)),
                    ),
                ],
              ),
            ),
          );
        });
      },
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      final evId =
          existing?.id ?? 'ev_${DateTime.now().millisecondsSinceEpoch}';
      await _store.upsertEvent(CalEvent(
        id: evId,
        title: title.text.trim(),
        note: note.text.trim().isEmpty ? null : note.text.trim(),
        start: start,
        end: allDay ? null : end,
        allDay: allDay,
        categoryId: cat,
        recurrence: recurrence,
        reminderMinutes: reminder,
        colorValue: existing?.colorValue ?? 0xFF42A5F5,
      ));
      try {
        await AppNotifications.instance.scheduleEventReminder(
          eventId: evId,
          title: title.text.trim(),
          start: start,
          reminderMinutes: reminder,
        );
      } catch (_) {}
      setState(() {});
    }
    title.dispose();
    note.dispose();
  }

  Future<void> _editNote(CalNote? existing) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'یادداشت' : 'ویرایش',
            style: const TextStyle(fontFamily: 'Vazirmatn')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'عنوان'),
                style: const TextStyle(fontFamily: 'Vazirmatn')),
            TextField(
                controller: body,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'متن'),
                style: const TextStyle(fontFamily: 'Vazirmatn')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف',
                  style: TextStyle(fontFamily: 'Vazirmatn'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ذخیره',
                  style: TextStyle(fontFamily: 'Vazirmatn'))),
        ],
      ),
    );
    if (ok == true) {
      await _store.upsertNote(CalNote(
        id: existing?.id ?? 'nt_${DateTime.now().millisecondsSinceEpoch}',
        title: title.text.trim(),
        body: body.text.trim(),
        day: existing?.day ?? _selectedG,
      ));
      setState(() {});
    }
    title.dispose();
    body.dispose();
  }

  Future<void> _editTask(CalTask? existing) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسک', style: TextStyle(fontFamily: 'Vazirmatn')),
        content: TextField(
            controller: title,
            autofocus: true,
            style: const TextStyle(fontFamily: 'Vazirmatn'),
            decoration: const InputDecoration(labelText: 'عنوان کار')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف',
                  style: TextStyle(fontFamily: 'Vazirmatn'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ذخیره',
                  style: TextStyle(fontFamily: 'Vazirmatn'))),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      await _store.upsertTask(CalTask(
        id: existing?.id ?? 'tk_${DateTime.now().millisecondsSinceEpoch}',
        title: title.text.trim(),
        due: existing?.due ?? _selectedG ?? DateTime.now(),
      ));
      setState(() {});
    }
    title.dispose();
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setL) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تنظیمات تقویم',
                    style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _store.settings.defaultView,
                  decoration: const InputDecoration(
                    labelText: 'نمای پیش‌فرض',
                    labelStyle: TextStyle(fontFamily: 'Vazirmatn'),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'month',
                        child: Text('ماه',
                            style: TextStyle(fontFamily: 'Vazirmatn'))),
                    DropdownMenuItem(
                        value: 'week',
                        child: Text('هفته',
                            style: TextStyle(fontFamily: 'Vazirmatn'))),
                    DropdownMenuItem(
                        value: 'day',
                        child: Text('روز',
                            style: TextStyle(fontFamily: 'Vazirmatn'))),
                    DropdownMenuItem(
                        value: 'agenda',
                        child: Text('فهرست',
                            style: TextStyle(fontFamily: 'Vazirmatn'))),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setL(() => _store.settings.defaultView = v);
                    await _store.saveSettings();
                    setState(() => _view = v);
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('نمایش مناسبت‌ها',
                      style: TextStyle(fontFamily: 'Vazirmatn')),
                  value: _store.settings.showOccasions,
                  onChanged: (v) async {
                    setL(() => _store.settings.showOccasions = v);
                    await _store.saveSettings();
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('نمایش تعطیلات',
                      style: TextStyle(fontFamily: 'Vazirmatn')),
                  value: _store.settings.showHolidays,
                  onChanged: (v) async {
                    setL(() => _store.settings.showHolidays = v);
                    await _store.saveSettings();
                    setState(() {});
                  },
                ),
                ListTile(
                  title: Text('شهر اوقات شرعی: ${_store.settings.prayerCity}',
                      style: const TextStyle(fontFamily: 'Vazirmatn')),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () async {
                    final c = await showDialog<String>(
                      context: ctx,
                      builder: (c2) => SimpleDialog(
                        title: const Text('شهر',
                            style: TextStyle(fontFamily: 'Vazirmatn')),
                        children: [
                          for (final name in _cities.keys)
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(c2, name),
                              child: Text(name,
                                  style: const TextStyle(
                                      fontFamily: 'Vazirmatn')),
                            ),
                        ],
                      ),
                    );
                    if (c != null) {
                      final ll = _cities[c]!;
                      setL(() {
                        _store.settings.prayerCity = c;
                        _store.settings.cityLat = ll[0];
                        _store.settings.cityLng = ll[1];
                      });
                      await _store.saveSettings();
                    }
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }



  void _openReminders() {
    final now = DateTime.now();
    final items = <Map<String, String>>[];
    for (final e in _store.events) {
      if (e.reminderMinutes <= 0) continue;
      if (e.start.isBefore(now.subtract(const Duration(days: 1)))) continue;
      if (e.start.isAfter(now.add(const Duration(days: 14)))) continue;
      final j = Jalali.fromDateTime(e.start);
      final rem = e.reminderMinutes == 1440
          ? '۱ روز قبل'
          : e.reminderMinutes == 60
              ? '۱ ساعت قبل'
              : '${e.reminderMinutes} دقیقه قبل';
      items.add({
        'title': e.title,
        'when': '${j.day} ${j.monthName} ${j.year} · $rem',
      });
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'یادآورها',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28, horizontal: 12),
                child: Text(
                  'یادآوری فعالی در دو هفته آینده نیست.\nروی رویدادها یادآوری بگذارید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Vazirmatn'),
                ),
              )
            else
              SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.4,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.alarm),
                    title: Text(items[i]['title']!,
                        style: const TextStyle(fontFamily: 'Vazirmatn')),
                    subtitle: Text(items[i]['when']!,
                        style: const TextStyle(
                            fontFamily: 'Vazirmatn', fontSize: 12)),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'اعلان سیستم‌عامل فعال است؛ اجازه اعلان را در تنظیمات گوشی بررسی کنید.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: Theme.of(ctx)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDateConverter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DateConverterSheet(
        onGoToDate: (g) {
          Navigator.of(context).pop();
          setState(() {
            _selectedG = g;
            final j = Jalali.fromDateTime(g);
            _focused = Jalali(j.year, j.month, 1);
            _view = 'month';
          });
        },
      ),
    );
  }

  void _openTools() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('ابزارهای تقویم',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const Divider(),
            _toolTile(Icons.compare_arrows_rounded, 'مبدل تاریخ',
                _openDateConverter),
            _toolTile(Icons.notifications_active_outlined, 'یادآورها',
                _openReminders),
            _toolTile(Icons.settings_outlined, 'تنظیمات تقویم',
                _openSettings),
            _toolTile(Icons.mosque, 'اوقات شرعی', _showPrayer),
            _toolTile(Icons.explore, 'زاویه قبله', _showQibla),
            _toolTile(Icons.fingerprint, 'ذکرشمار', _showDhikr),
            _toolTile(Icons.menu_book, 'ادعیه نمونه', _showDuas),
            _toolTile(Icons.cake, 'مناسبت شخصی', _showPersonalOcc),
            _toolTile(Icons.account_balance_wallet, 'بخش مالی اپ', () {
              Navigator.pop(context);
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FinanceScreen()));
            }),
            const SizedBox(height: 8),
            Text(
              'اعلان سیستم‌عامل برای رویدادها و اقساط فعال است (در تنظیمات گوشی اجازه اعلان بدهید). اوقات شرعی تقریبی‌اند و مرجع رسمی نیستند.',
              style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontFamily: 'Vazirmatn')),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showPrayer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var day = _selectedG ?? DateTime.now();
        return StatefulBuilder(builder: (ctx, setL) {
          final j = Jalali.fromDateTime(day);
          final h = HijriDate.fromGregorian(day);
          final map = PrayerTimesApprox.compute(
              day, _store.settings.cityLat, _store.settings.cityLng);
          final now = DateTime.now();
          final isToday = day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;
          final nowT = TimeOfDay.fromDateTime(now);
          String? nextName;
          TimeOfDay? nextTime;
          if (isToday) {
            for (final e in map.entries) {
              final t = e.value;
              final mins = t.hour * 60 + t.minute;
              final nowM = nowT.hour * 60 + nowT.minute;
              if (mins >= nowM) {
                nextName = e.key;
                nextTime = t;
                break;
              }
            }
          }

          IconData iconFor(String name) {
            if (name.contains('صبح')) return Icons.nights_stay_outlined;
            if (name.contains('طلوع')) return Icons.wb_twilight_outlined;
            if (name.contains('ظهر')) return Icons.wb_sunny_outlined;
            if (name.contains('عصر')) return Icons.wb_cloudy_outlined;
            if (name.contains('غروب')) return Icons.wb_twilight;
            if (name.contains('مغرب')) return Icons.nightlight_round;
            if (name.contains('عشا')) return Icons.dark_mode_outlined;
            return Icons.schedule;
          }

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.92,
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: [
                // هدر تصویری
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF5D4037), Color(0xFFBF360C), Color(0xFFFF8A65)],
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.arrow_forward,
                                  color: Colors.white),
                            ),
                            const Expanded(
                              child: Text(
                                'اوقات شرعی',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (nextName != null && nextTime != null)
                          Text(
                            '$nextName  ${PrayerTimesApprox.fmt(nextTime)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Text(
                            'اوقات امروز',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  _store.settings.prayerCity,
                                  style: const TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ناوبری روز
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => setL(() {
                          day = day.add(const Duration(days: 1));
                        }),
                        child: const Text('روز بعد',
                            style: TextStyle(fontFamily: 'Vazirmatn')),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${Jalali.weekDays[j.weekdayIndex]} ${j.day} ${j.monthName} ${j.year}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${h.day} ${HijriDate.monthNames[h.month - 1]} ${h.year}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                color: Theme.of(ctx)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setL(() {
                          day = day.subtract(const Duration(days: 1));
                        }),
                        child: const Text('روز قبل',
                            style: TextStyle(fontFamily: 'Vazirmatn')),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      for (final e in map.entries)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: e.key == nextName
                                ? const Color(0xFFFFE0B2).withValues(alpha: 0.7)
                                : Theme.of(ctx)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(iconFor(e.key),
                                  color: const Color(0xFFBF360C), size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: const TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                PrayerTimesApprox.fmt(e.value),
                                style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  color: Color(0xFFBF360C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'محاسبه تقریبی نجومی است و جایگزین اوقات رسمی اوقاف نیست. برای دقت بیشتر شهر را از تنظیمات تقویم انتخاب کنید.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color: Theme.of(ctx)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showQibla() {
    final lat = _store.settings.cityLat;
    final lng = _store.settings.cityLng;
    final br = PrayerTimesApprox.qiblaBearing(lat, lng);
    final season = SeasonTheme.ofJalali(_selectedJ);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('جهت قبله',
                style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              _store.settings.prayerCity,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                color: Theme.of(ctx)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              width: 200,
              child: CustomPaint(
                painter: _QiblaCompassPainter(
                  bearing: br,
                  color: season.primary,
                  soft: season.soft,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${br.toStringAsFixed(1)}°',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w900,
                fontSize: 32,
                color: season.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'از شمال جغرافیایی به سمت قبله',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                color: Theme.of(ctx)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'قطب‌نما روی گوشی را با شمال واقعی هم‌راستا کنید؛ این عدد زاویه ثابت نسبت به شمال است.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11.5,
                color: Theme.of(ctx)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDhikr() {
    final season = SeasonTheme.ofJalali(_selectedJ);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setL) {
          final d = _store.dhikr;
          final progress =
              d.target <= 0 ? 0.0 : (d.count / d.target).clamp(0.0, 1.0);
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                const Text('ذکرشمار',
                    style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in DuaCatalog.dhikrPresets)
                      ActionChip(
                        label: Text(p['name'] as String,
                            style: const TextStyle(
                                fontFamily: 'Vazirmatn', fontSize: 12)),
                        onPressed: () async {
                          setL(() {
                            _store.dhikr.name = p['name'] as String;
                            _store.dhikr.target = p['target'] as int;
                            _store.dhikr.count = 0;
                          });
                          await _store.saveDhikr();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(d.name,
                    style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: season.primary)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  width: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 160,
                        width: 160,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: season.soft,
                          color: season.primary,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${d.count}',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontWeight: FontWeight.w900,
                              fontSize: 40,
                              color: season.primary,
                            ),
                          ),
                          Text(
                            'از ${d.target}',
                            style: const TextStyle(
                                fontFamily: 'Vazirmatn', fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          setL(() => _store.dhikr.count = 0);
                          await _store.saveDhikr();
                        },
                        child: const Text('صفر',
                            style: TextStyle(fontFamily: 'Vazirmatn')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: season.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          setL(() => _store.dhikr.count++);
                          await _store.saveDhikr();
                          if (_store.dhikr.count >= _store.dhikr.target &&
                              _store.dhikr.target > 0) {
                            // soft feedback via snack
                          }
                        },
                        child: const Text('ذکر +',
                            style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'با لمس دکمه بشمارید؛ پیشرفت ذخیره می‌شود.',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showDuas() {
    final season = SeasonTheme.ofJalali(_selectedJ);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text('ادعیه و اذکار',
                style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: DuaCatalog.items.length,
                itemBuilder: (_, i) {
                  final d = DuaCatalog.items[i];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    color: i.isEven
                        ? season.soft.withValues(alpha: 0.45)
                        : Theme.of(ctx)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(d['title']!,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.w800,
                                color: season.primary,
                              )),
                          const SizedBox(height: 8),
                          Text(
                            d['ar']!,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 18,
                              height: 1.6,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d['fa']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              color: Theme.of(ctx)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonalOcc() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                    child: Text('مناسبت‌های شخصی',
                        style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.w800))),
                TextButton(
                  onPressed: () async {
                    final title = TextEditingController();
                    final j = _selectedJ;
                    final ok = await showDialog<bool>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        title: const Text('مناسبت سالانه',
                            style: TextStyle(fontFamily: 'Vazirmatn')),
                        content: TextField(
                            controller: title,
                            style: const TextStyle(fontFamily: 'Vazirmatn'),
                            decoration: const InputDecoration(
                                labelText: 'مثلاً تولد ...')),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('انصراف',
                                  style:
                                      TextStyle(fontFamily: 'Vazirmatn'))),
                          TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('ثبت',
                                  style:
                                      TextStyle(fontFamily: 'Vazirmatn'))),
                        ],
                      ),
                    );
                    if (ok == true && title.text.trim().isNotEmpty) {
                      await _store.upsertPersonal(PersonalOccasion(
                        id: 'po_${DateTime.now().millisecondsSinceEpoch}',
                        title: title.text.trim(),
                        month: j.month,
                        day: j.day,
                      ));
                      setState(() {});
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                    title.dispose();
                  },
                  child: const Text('افزودن برای روز انتخاب‌شده',
                      style: TextStyle(fontFamily: 'Vazirmatn')),
                ),
              ],
            ),
            for (final o in _store.personalOccasions)
              ListTile(
                title: Text(o.title,
                    style: const TextStyle(fontFamily: 'Vazirmatn')),
                subtitle: Text(
                  '${o.day} ${Jalali.monthNames[o.month - 1]} (هر سال)',
                  style: const TextStyle(fontFamily: 'Vazirmatn'),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await _store.removePersonal(o.id);
                    setState(() {});
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}


/// نقاش قطب‌نمای قبله (سطح بالا — خارج از State)
class _QiblaCompassPainter extends CustomPainter {
  final double bearing;
  final Color color;
  final Color soft;
  _QiblaCompassPainter({
    required this.bearing,
    required this.color,
    required this.soft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    final bg = Paint()..color = soft.withValues(alpha: 0.7);
    canvas.drawCircle(c, r, bg);
    final ring = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(c, r, ring);

    final textPainter = TextPainter(textDirection: TextDirection.rtl);
    void label(String s, Offset o) {
      textPainter.text = TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, o - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    label('ش', c + Offset(0, -r + 14));
    label('ج', c + Offset(0, r - 14));
    label('ق', c + Offset(-r + 14, 0));
    label('ش‌ر', c + Offset(r - 18, 0));

    final rad = (bearing - 90) * math.pi / 180;
    final tip = c + Offset(math.cos(rad) * (r - 24), math.sin(rad) * (r - 24));
    final needle = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, tip, needle);
    canvas.drawCircle(c, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _QiblaCompassPainter old) =>
      old.bearing != bearing || old.color != color;
}
