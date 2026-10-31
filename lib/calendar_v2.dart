// تقویم ۲.۰ — رویداد، یادداشت، تسک، ابزارها (متصل به Jalali موجود)
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
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

  List<CalEvent> events = [];
  List<CalNote> notes = [];
  List<CalTask> tasks = [];
  List<CalCategory> categories = List.from(CalCategory.defaults);
  List<PersonalOccasion> personalOccasions = [];
  CalSettings settings = CalSettings();
  DhikrState dhikr = DhikrState();
  String? lastError;

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
  }

  Future<void> removeEvent(String id) async {
    events.removeWhere((e) => e.id == id);
    await _save(_kEvents, events);
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

// ─── اوقات شرعی تقریبی (الگوریتم ساده — نه ادعای دقت رسمی) ───
class PrayerTimesApprox {
  /// خروجی: نام → TimeOfDay تقریبی بر اساس عرض جغرافیایی و روز سال
  static Map<String, TimeOfDay> compute(DateTime date, double lat, double lng) {
    final day = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final decl = 23.45 * math.sin((360 / 365) * (day - 81) * math.pi / 180);
    double hourAngle(double elev) {
      final latR = lat * math.pi / 180;
      final dR = decl * math.pi / 180;
      final cosH = (math.sin(elev * math.pi / 180) -
              math.sin(latR) * math.sin(dR)) /
          (math.cos(latR) * math.cos(dR));
      final c = cosH.clamp(-1.0, 1.0);
      return math.acos(c) * 180 / math.pi / 15;
    }

    final noon = 12 - lng / 15; // تقریب
    final haSunrise = hourAngle(-0.833);
    final haFajr = hourAngle(-18); // زاویه تقریبی
    final haIsha = hourAngle(-18);
    TimeOfDay td(double h) {
      var x = h % 24;
      if (x < 0) x += 24;
      final hh = x.floor();
      final mm = ((x - hh) * 60).round().clamp(0, 59);
      return TimeOfDay(hour: hh, minute: mm);
    }

    return {
      'اذان صبح': td(noon - haFajr),
      'طلوع': td(noon - haSunrise),
      'ظهر': td(noon),
      'غروب': td(noon + haSunrise),
      'مغرب': td(noon + haSunrise + 0.15),
      'عشاء': td(noon + haIsha),
    };
  }

  static double qiblaBearing(double lat, double lng) {
    // کعبه
    const kLat = 21.4225 * math.pi / 180;
    const kLng = 39.8262 * math.pi / 180;
    final latR = lat * math.pi / 180;
    final dLng = (39.8262 - lng) * math.pi / 180;
    final x = math.sin(dLng);
    final y = math.cos(latR) * math.tan(kLat) - math.sin(latR) * math.cos(dLng);
    var br = math.atan2(x, y) * 180 / math.pi;
    br = (br + 360) % 360;
    return br;
  }
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
    _load();
  }

  @override
  void dispose() {
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
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      '${_focused.year}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.55),
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
    // شنبه محور
    final wd = base.weekday; // mon=1
    final back = wd == 6 ? 0 : (wd == 7 ? 1 : wd + 1);
    final start = DateTime(base.year, base.month, base.day)
        .subtract(Duration(days: back));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
      itemCount: 7,
      itemBuilder: (_, i) {
        final day = start.add(Duration(days: i));
        final j = Jalali.fromDateTime(day);
        final evs = _store.occurrencesOn(day);
        return Card(
          child: ListTile(
            title: Text(
              '${Jalali.weekDays[j.weekdayIndex]} ${j.day} ${j.monthName}',
              style: const TextStyle(
                  fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              evs.isEmpty
                  ? '—'
                  : evs.map((e) => e.title).take(3).join(' · '),
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
            ),
            onTap: () => setState(() {
              _selectedG = day;
              _view = 'day';
            }),
          ),
        );
      },
    );
  }

  Widget _buildDay(ColorScheme scheme) => _dayPanel(scheme);

  Widget _buildAgenda(ColorScheme scheme) {
    final now = DateTime.now();
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < 60; i++) {
      final d = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      for (final e in _store.occurrencesOn(d)) {
        items.add({'d': d, 'e': e});
      }
    }
    if (items.isEmpty) {
      return const Center(
          child: Text('رویداد آینده‌ای نیست',
              style: TextStyle(fontFamily: 'Vazirmatn')));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final d = items[i]['d'] as DateTime;
        final e = items[i]['e'] as CalEvent;
        final j = Jalali.fromDateTime(d);
        return ListTile(
          title: Text(e.title, style: const TextStyle(fontFamily: 'Vazirmatn')),
          subtitle: Text(
            '${j.day} ${j.monthName} · ${e.allDay ? 'تمام‌روز' : '${e.start.hour}:${e.start.minute.toString().padLeft(2, '0')}'}',
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
          ),
          onTap: () => _editEvent(e),
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
      await _store.upsertEvent(CalEvent(
        id: existing?.id ?? 'ev_${DateTime.now().millisecondsSinceEpoch}',
        title: title.text.trim(),
        note: note.text.trim().isEmpty ? null : note.text.trim(),
        start: start,
        allDay: allDay,
        categoryId: cat,
        recurrence: recurrence,
        reminderMinutes: reminder,
        colorValue: existing?.colorValue ?? 0xFF42A5F5,
      ));
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
            _toolTile(Icons.mosque, 'اوقات شرعی (تقریبی)', _showPrayer),
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
              'اعلان سیستم‌عامل در این نسخه فعال نیست؛ یادآوری‌ها داخل تقویم و هنگام باز کردن برنامه قابل مشاهده‌اند. اوقات شرعی تقریبی‌اند و مرجع رسمی نیستند.',
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
    final g = _selectedG ?? DateTime.now();
    final map = PrayerTimesApprox.compute(
        g, _store.settings.cityLat, _store.settings.cityLng);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('اوقات شرعی — ${_store.settings.prayerCity}',
                style: const TextStyle(
                    fontFamily: 'Vazirmatn', fontWeight: FontWeight.w800)),
            Text('تقریبی و غیررسمی',
                style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5))),
            for (final e in map.entries)
              ListTile(
                title: Text(e.key,
                    style: const TextStyle(fontFamily: 'Vazirmatn')),
                trailing: Text(
                  '${e.value.hour.toString().padLeft(2, '0')}:${e.value.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showQibla() {
    final br = PrayerTimesApprox.qiblaBearing(
        _store.settings.cityLat, _store.settings.cityLng);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('زاویه قبله',
            style: TextStyle(fontFamily: 'Vazirmatn')),
        content: Text(
          'از موقعیت «${_store.settings.prayerCity}»\nزاویه قبله نسبت به شمال جغرافیایی:\n\n${br.toStringAsFixed(1)} درجه\n\nقطب‌نمای زنده حسگر در این نسخه فعال نیست؛ فقط زاویه محاسبه‌شده نمایش داده می‌شود.',
          style: const TextStyle(fontFamily: 'Vazirmatn'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('باشه',
                  style: TextStyle(fontFamily: 'Vazirmatn'))),
        ],
      ),
    );
  }

  void _showDhikr() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setL) {
          final d = _store.dhikr;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(d.name,
                    style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text('${d.count} / ${d.target}',
                    style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 36,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(64)),
                  onPressed: () async {
                    setL(() => d.count++);
                    await _store.saveDhikr();
                  },
                  child: const Text('ذکر',
                      style: TextStyle(
                          fontFamily: 'Vazirmatn', fontSize: 18)),
                ),
                TextButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        title: const Text('صفر شود؟',
                            style: TextStyle(fontFamily: 'Vazirmatn')),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('خیر',
                                  style: TextStyle(fontFamily: 'Vazirmatn'))),
                          TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('بله',
                                  style: TextStyle(fontFamily: 'Vazirmatn'))),
                        ],
                      ),
                    );
                    if (ok == true) {
                      setL(() => d.count = 0);
                      await _store.saveDhikr();
                    }
                  },
                  child: const Text('صفر',
                      style: TextStyle(fontFamily: 'Vazirmatn')),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showDuas() {
    const duas = [
      (
        'دعای فرج',
        'اللّهُمَّ کُنْ لِوَلِیِّکَ ... (متن کامل از منابع معتبر مراجعه شود)',
        'منبع: متون رایج — برای صحت به منبع رسمی رجوع کنید'
      ),
      (
        'ذکر یونسیه',
        'لا إِلهَ إِلّا أَنْتَ سُبْحانَکَ إِنّی کُنْتُ مِنَ الظّالِمینَ',
        'قرآن کریم، سوره انبیاء'
      ),
    ];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('ادعیه نمونه',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Vazirmatn', fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final d in duas)
            Card(
              child: ListTile(
                title: Text(d.$1,
                    style: const TextStyle(
                        fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700)),
                subtitle: Text('${d.$2}\n${d.$3}',
                    style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                isThreeLine: true,
              ),
            ),
        ],
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
                subtitle: Text('${o.day} / ${o.month}',
                    style: const TextStyle(fontFamily: 'Vazirmatn')),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await _store.removePersonal(o.id);
                    setState(() {});
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
