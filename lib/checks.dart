// ===== checks.dart — ماژول چک‌های من =====
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'core.dart';
import 'features.dart'
    show Expense, ExpenseStore, Jalali, showJalaliDatePicker;
import 'notifications.dart';
import 'calendar_v2.dart' show CalEvent, CalendarStore;


/// تطبیق نام بانک ایرانی با لوگوی واقعی (SVG در assets/banks)
class BankVisual {
  final String asset; // مسیر asset یا خالی
  final String letter;
  final Color color;
  const BankVisual({required this.asset, required this.letter, required this.color});

  static const _defs = <String, BankVisual>{
    'ملی': BankVisual(asset: 'assets/banks/melli.svg', letter: 'مل', color: Color(0xFF1B5E20)),
    'ملت': BankVisual(asset: 'assets/banks/mellat.svg', letter: 'مت', color: Color(0xFFB71C1C)),
    'صادرات': BankVisual(asset: 'assets/banks/saderat.svg', letter: 'صا', color: Color(0xFF0D47A1)),
    'تجارت': BankVisual(asset: 'assets/banks/tejarat.svg', letter: 'تج', color: Color(0xFFE65100)),
    'سپه': BankVisual(asset: 'assets/banks/sepah.svg', letter: 'سپ', color: Color(0xFF4A148C)),
    'کشاورزی': BankVisual(asset: 'assets/banks/keshavarzi.svg', letter: 'کش', color: Color(0xFF33691E)),
    'مسکن': BankVisual(asset: 'assets/banks/maskan.svg', letter: 'مس', color: Color(0xFF37474F)),
    'پارسیان': BankVisual(asset: 'assets/banks/parsian.svg', letter: 'پا', color: Color(0xFFBF360C)),
    'پاسارگاد': BankVisual(asset: 'assets/banks/pasargad.svg', letter: 'پس', color: Color(0xFF1A237E)),
    'سامان': BankVisual(asset: 'assets/banks/saman.svg', letter: 'سا', color: Color(0xFF1565C0)),
    'سینا': BankVisual(asset: 'assets/banks/sina.svg', letter: 'سی', color: Color(0xFF4527A0)),
    'شهر': BankVisual(asset: 'assets/banks/shahr.svg', letter: 'شه', color: Color(0xFF263238)),
    'دی': BankVisual(asset: 'assets/banks/dey.svg', letter: 'دی', color: Color(0xFF01579B)),
    'ایران زمین': BankVisual(asset: 'assets/banks/iranzamin.svg', letter: 'از', color: Color(0xFF3E2723)),
    'کارآفرین': BankVisual(asset: 'assets/banks/karafarin.svg', letter: 'کا', color: Color(0xFF827717)),
    'رسالت': BankVisual(asset: 'assets/banks/resalat.svg', letter: 'رس', color: Color(0xFF1B5E20)),
    'مهر': BankVisual(asset: 'assets/banks/mehriran.svg', letter: 'مه', color: Color(0xFF33691E)),
    'پست': BankVisual(asset: 'assets/banks/post.svg', letter: 'پست', color: Color(0xFF5D4037)),
    'گردشگری': BankVisual(asset: 'assets/banks/gardeshgari.svg', letter: 'گر', color: Color(0xFF004D40)),
    'خاورمیانه': BankVisual(asset: 'assets/banks/khavarmianeh.svg', letter: 'خا', color: Color(0xFF0D47A1)),
    'صنعت': BankVisual(asset: 'assets/banks/sanatmadan.svg', letter: 'صن', color: Color(0xFF455A64)),
    'آینده': BankVisual(asset: 'assets/banks/ayandeh.svg', letter: 'آی', color: Color(0xFF006064)),
    'سرمایه': BankVisual(asset: 'assets/banks/sarmayeh.svg', letter: 'سر', color: Color(0xFF6A1B9A)),
    'انصار': BankVisual(asset: 'assets/banks/ansar.svg', letter: 'ان', color: Color(0xFFC62828)),
    'حکمت': BankVisual(asset: 'assets/banks/hekmat.svg', letter: 'حک', color: Color(0xFF283593)),
    'کوثر': BankVisual(asset: 'assets/banks/kosar.svg', letter: 'کو', color: Color(0xFF6A1B9A)),
  };

  static BankVisual? match(String name) {
    final n = name.trim();
    if (n.isEmpty) return null;
    for (final e in _defs.entries) {
      if (n.contains(e.key)) return e.value;
    }
    return BankVisual(
      asset: '',
      letter: n.substring(0, 1),
      color: const Color(0xFF546E7A),
    );
  }

  /// ویجت لوگوی واقعی یا fallback حرف
  static Widget logo(String? bankName, {double size = 28}) {
    final v = match(bankName ?? '');
    if (v == null || (bankName ?? '').trim().isEmpty) {
      return Icon(Icons.account_balance_outlined, size: size * 0.85);
    }
    if (v.asset.isNotEmpty) {
      return SvgPicture.asset(
        v.asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _fallback(v, size),
      );
    }
    return _fallback(v, size);
  }

  static Widget _fallback(BankVisual v, double size) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: v.color, shape: BoxShape.circle),
      child: Text(
        v.letter,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          color: Colors.white,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}


/// مبلغ با جداکننده هزارگان + ارقام فارسی/عربی → لاتین
class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = NumFmt.groupTyping(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// شناسه صیادی ۱۶ رقم، گروه‌بندی ۴تایی
class SayadInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = NumFmt.toLatinDigits(newValue.text).replaceAll(RegExp(r'\D'), '');
    if (digits.length > 16) digits = digits.substring(0, 16);
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final t = buf.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}


enum CheckKind { received, paid }

extension CheckKindX on CheckKind {
  String get code => this == CheckKind.received ? 'received' : 'paid';
  String get label => this == CheckKind.received ? 'دریافتی' : 'پرداختی';
  static CheckKind from(String? s) =>
      s == 'paid' ? CheckKind.paid : CheckKind.received;
}

class CheckStatus {
  static const pending = 'pending';
  static const settled = 'settled';
  static const bounced = 'bounced';
  static const transferred = 'transferred';
  static const voided = 'voided';

  static String label(CheckKind kind, String status) {
    switch (status) {
      case settled:
        return kind == CheckKind.received ? 'وصول شد' : 'پاس شد';
      case bounced:
        return 'برگشت خورد';
      case transferred:
        return 'منتقل شد';
      case voided:
        return 'باطل شد';
      default:
        return kind == CheckKind.received
            ? 'در انتظار وصول'
            : 'در انتظار پاس‌شدن';
    }
  }

  static bool isFinal(String s) =>
      s == settled || s == transferred || s == voided;
}

class CheckStatusChange {
  final String from;
  final String to;
  final DateTime at;
  final String? note;
  CheckStatusChange(
      {required this.from, required this.to, required this.at, this.note});
  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'at': at.toIso8601String(),
        'note': note,
      };
  factory CheckStatusChange.fromJson(Map<String, dynamic> j) =>
      CheckStatusChange(
        from: j['from'] as String? ?? '',
        to: j['to'] as String? ?? '',
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
        note: j['note'] as String?,
      );
}

class BankCheck {
  final String id;
  final CheckKind kind;
  final double amount;
  final DateTime dueDate;
  final DateTime? issueDate;
  final String personName;
  final String? checkNumber;
  final String? sayadId;
  final String? bankName;
  final String? phone;
  final String? description;
  final String? imagePath;
  final String? imagePathBack;
  final String status;
  final bool remindersEnabled;
  final List<int> reminderDays;
  final List<CheckStatusChange> history;
  final String? linkedExpenseId;
  final DateTime createdAt;
  final DateTime updatedAt;

  BankCheck({
    required this.id,
    required this.kind,
    required this.amount,
    required this.dueDate,
    this.issueDate,
    required this.personName,
    this.checkNumber,
    this.sayadId,
    this.bankName,
    this.phone,
    this.description,
    this.imagePath,
    this.imagePathBack,
    this.status = CheckStatus.pending,
    this.remindersEnabled = true,
    this.reminderDays = const [7, 3, 1, 0],
    this.history = const [],
    this.linkedExpenseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isOpen =>
      status == CheckStatus.pending || status == CheckStatus.bounced;

  bool get isDueToday {
    final n = DateTime.now();
    return dueDate.year == n.year &&
        dueDate.month == n.month &&
        dueDate.day == n.day;
  }

  bool get isOverdue {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return isOpen && due.isBefore(today);
  }

  bool get isUpcoming {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return isOpen && due.isAfter(today);
  }

  String get statusLabel => CheckStatus.label(kind, status);

  Color statusColor(ColorScheme scheme) {
    switch (status) {
      case CheckStatus.settled:
        return Colors.green.shade700;
      case CheckStatus.bounced:
        return Colors.red.shade700;
      case CheckStatus.transferred:
        return Colors.blue.shade700;
      case CheckStatus.voided:
        return scheme.outline;
      default:
        if (isOverdue) return Colors.deepOrange.shade700;
        if (isDueToday) return Colors.amber.shade800;
        return scheme.primary;
    }
  }

  BankCheck copyWith({
    CheckKind? kind,
    double? amount,
    DateTime? dueDate,
    DateTime? issueDate,
    bool clearIssueDate = false,
    String? personName,
    String? checkNumber,
    String? sayadId,
    String? bankName,
    String? phone,
    String? description,
    String? imagePath,
    bool clearImage = false,
    String? imagePathBack,
    bool clearImageBack = false,
    String? status,
    bool? remindersEnabled,
    List<int>? reminderDays,
    List<CheckStatusChange>? history,
    String? linkedExpenseId,
    bool clearLinked = false,
  }) =>
      BankCheck(
        id: id,
        kind: kind ?? this.kind,
        amount: amount ?? this.amount,
        dueDate: dueDate ?? this.dueDate,
        issueDate: clearIssueDate ? null : (issueDate ?? this.issueDate),
        personName: personName ?? this.personName,
        checkNumber: checkNumber ?? this.checkNumber,
        sayadId: sayadId ?? this.sayadId,
        bankName: bankName ?? this.bankName,
        phone: phone ?? this.phone,
        description: description ?? this.description,
        imagePath: clearImage ? null : (imagePath ?? this.imagePath),
        imagePathBack:
            clearImageBack ? null : (imagePathBack ?? this.imagePathBack),
        status: status ?? this.status,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        reminderDays: reminderDays ?? this.reminderDays,
        history: history ?? this.history,
        linkedExpenseId:
            clearLinked ? null : (linkedExpenseId ?? this.linkedExpenseId),
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.code,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'issueDate': issueDate?.toIso8601String(),
        'personName': personName,
        'checkNumber': checkNumber,
        'sayadId': sayadId,
        'bankName': bankName,
        'phone': phone,
        'description': description,
        'imagePath': imagePath,
        'imagePathBack': imagePathBack,
        'status': status,
        'remindersEnabled': remindersEnabled,
        'reminderDays': reminderDays,
        'history': history.map((e) => e.toJson()).toList(),
        'linkedExpenseId': linkedExpenseId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BankCheck.fromJson(Map<String, dynamic> j) {
    final hist = <CheckStatusChange>[];
    final rawH = j['history'];
    if (rawH is List) {
      for (final e in rawH) {
        try {
          if (e is Map<String, dynamic>) {
            hist.add(CheckStatusChange.fromJson(e));
          } else if (e is Map) {
            hist.add(
                CheckStatusChange.fromJson(Map<String, dynamic>.from(e)));
          }
        } catch (_) {}
      }
    }
    final days = <int>[];
    final rawD = j['reminderDays'];
    if (rawD is List) {
      for (final e in rawD) {
        if (e is num) days.add(e.toInt());
      }
    }
    return BankCheck(
      id: j['id'] as String? ??
          'chk_${DateTime.now().millisecondsSinceEpoch}',
      kind: CheckKindX.from(j['kind'] as String?),
      amount: (j['amount'] as num?)?.toDouble() ?? 0,
      dueDate: DateTime.tryParse(j['dueDate'] as String? ?? '') ??
          DateTime.now(),
      issueDate: j['issueDate'] != null
          ? DateTime.tryParse(j['issueDate'] as String)
          : null,
      personName: j['personName'] as String? ?? '',
      checkNumber: j['checkNumber'] as String?,
      sayadId: j['sayadId'] as String?,
      bankName: j['bankName'] as String?,
      phone: j['phone'] as String?,
      description: j['description'] as String?,
      imagePath: j['imagePath'] as String?,
      imagePathBack: j['imagePathBack'] as String?,
      status: j['status'] as String? ?? CheckStatus.pending,
      remindersEnabled: j['remindersEnabled'] as bool? ?? true,
      reminderDays: days.isEmpty ? const [7, 3, 1, 0] : days,
      history: hist,
      linkedExpenseId: j['linkedExpenseId'] as String?,
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class CheckStore {
  CheckStore._();
  static final CheckStore instance = CheckStore._();
  static const storageKey = 'checks_v1';
  List<BankCheck> items = [];
  String? lastError;

  Future<void> load() async {
    lastError = null;
    try {
      final s = await LocalStore.instance;
      final raw = s.getString(storageKey);
      if (raw == null || raw.isEmpty) {
        items = [];
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        lastError = 'فرمت داده چک‌ها نامعتبر است';
        return;
      }
      final parsed = <BankCheck>[];
      var corrupt = 0;
      for (final e in decoded) {
        try {
          if (e is Map<String, dynamic>) {
            parsed.add(BankCheck.fromJson(e));
          } else if (e is Map) {
            parsed.add(BankCheck.fromJson(Map<String, dynamic>.from(e)));
          } else {
            corrupt++;
          }
        } catch (_) {
          corrupt++;
        }
      }
      parsed.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      items = parsed;
      if (corrupt > 0) {
        lastError = '$corrupt رکورد چک خراب نادیده گرفته شد';
      }
    } catch (e) {
      lastError = e.toString();
    }
  }

  Future<void> _save() async {
    final s = await LocalStore.instance;
    await s.setString(
        storageKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> upsert(BankCheck c) async {
    final snap = List<BankCheck>.from(items);
    final i = items.indexWhere((e) => e.id == c.id);
    if (i >= 0) {
      items[i] = c;
    } else {
      items.add(c);
    }
    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    try {
      await _save();
    } catch (e) {
      items
        ..clear()
        ..addAll(snap);
      rethrow;
    }
    // اعلان و تقویم جدا از ذخیره
    try {
      await _syncReminders(c);
    } catch (e) {
      debugPrint('CheckStore._syncReminders: $e');
    }
    try {
      await _syncCalendar(c);
    } catch (e) {
      debugPrint('CheckStore._syncCalendar wrap: $e');
    }
  }

  Future<void> remove(String id) async {
    final snap = List<BankCheck>.from(items);
    items.removeWhere((e) => e.id == id);
    try {
      await _save();
    } catch (e) {
      items
        ..clear()
        ..addAll(snap);
      rethrow;
    }
    try {
      await _cancelReminders(id);
    } catch (e) {
      debugPrint('CheckStore._cancelReminders: $e');
    }
    try {
      await _removeCalendar(id);
    } catch (e) {
      debugPrint('CheckStore._removeCalendar wrap: $e');
    }
  }

  Future<BankCheck> changeStatus(BankCheck c, String newStatus,
      {String? note}) async {
    if (c.status == newStatus) return c;
    final hist = List<CheckStatusChange>.from(c.history)
      ..add(CheckStatusChange(
          from: c.status, to: newStatus, at: DateTime.now(), note: note));
    final updated = c.copyWith(status: newStatus, history: hist);
    await upsert(updated);
    if (CheckStatus.isFinal(newStatus)) await _cancelReminders(c.id);
    return updated;
  }

  BankCheck? byId(String id) {
    try {
      return items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<BankCheck> get received =>
      items.where((e) => e.kind == CheckKind.received).toList();
  List<BankCheck> get paid =>
      items.where((e) => e.kind == CheckKind.paid).toList();
  List<BankCheck> get today =>
      items.where((e) => e.isDueToday && e.isOpen).toList();
  List<BankCheck> get upcoming => items.where((e) => e.isUpcoming).toList();
  List<BankCheck> get overdue => items.where((e) => e.isOverdue).toList();
  List<BankCheck> get bounced =>
      items.where((e) => e.status == CheckStatus.bounced).toList();

  double sumOf(List<BankCheck> list) =>
      list.fold(0.0, (s, e) => s + e.amount);

  /// شناسه پایدار اعلان — مستقل از hashCode دارت (بین اجراها ثابت)
  static int notifId(String checkId, int dayOffset) {
    var h = 2166136261;
    for (final u in checkId.codeUnits) {
      h ^= u;
      h = (h * 16777619) & 0x7fffffff;
    }
    final base = h % 900000;
    return 310000000 + base * 10 + (dayOffset.clamp(0, 9));
  }

  static String calendarEventId(String checkId) => 'chk_cal_$checkId';

  Future<void> _syncCalendar(BankCheck c) async {
    try {
      final cal = CalendarStore();
      await cal.load();
      final eid = calendarEventId(c.id);
      if (CheckStatus.isFinal(c.status) && c.status != CheckStatus.settled) {
        await cal.removeEvent(eid);
        return;
      }
      final start = DateTime(c.dueDate.year, c.dueDate.month, c.dueDate.day, 9);
      final title = 'چک ${c.kind.label}: ${c.personName}';
      final note =
          '${NumFmt.format(c.amount.round())} تومان · ${c.statusLabel}'
          '${c.bankName != null ? ' · ${c.bankName}' : ''}';
      await cal.upsertEvent(CalEvent(
        id: eid,
        title: title,
        note: note,
        start: start,
        allDay: true,
        categoryId: 'c_finance',
        colorValue: c.kind == CheckKind.received ? 0xFF2E7D32 : 0xFFC62828,
        recurrence: 'none',
        reminderMinutes: 0, // اعلان از خود چک مدیریت می‌شود
        done: CheckStatus.isFinal(c.status),
      ));
    } catch (e) {
      debugPrint('CheckStore._syncCalendar: $e');
    }
  }

  Future<void> _removeCalendar(String checkId) async {
    try {
      final cal = CalendarStore();
      await cal.load();
      await cal.removeEvent(calendarEventId(checkId));
    } catch (e) {
      debugPrint('CheckStore._removeCalendar: $e');
    }
  }

  Future<void> _cancelReminders(String id) async {
    for (final d in [0, 1, 3, 7, 14, 30]) {
      await AppNotifications.instance.cancel(notifId(id, d));
    }
  }

  Future<void> _syncReminders(BankCheck c) async {
    await _cancelReminders(c.id);
    if (!c.remindersEnabled || CheckStatus.isFinal(c.status)) return;
    final ok = await AppNotifications.instance.ensurePermissionForReminders();
    if (!ok) return;
    final due = DateTime(c.dueDate.year, c.dueDate.month, c.dueDate.day, 9);
    final dueLabel = jalaliLabel(c.dueDate);
    final amountLabel = NumFmt.format(c.amount.round());
    for (final daysBefore in c.reminderDays) {
      final when = due.subtract(Duration(days: daysBefore));
      final remain = daysBefore == 0
          ? 'امروز سررسید'
          : '$daysBefore روز تا سررسید';
      final body =
          'چک ${c.kind.label} · ${c.personName}\n'
          '$amountLabel تومان · سررسید $dueLabel\n'
          '$remain';
      await AppNotifications.instance.schedule(
        id: notifId(c.id, daysBefore),
        title: 'چک ${c.kind.label}',
        body: body,
        when: when,
        payload: 'check:${c.id}',
      );
    }
  }

  Future<void> rescheduleAll() async {
    for (final c in items) {
      await _syncReminders(c);
    }
  }
}

String jalaliLabel(DateTime d) {
  final j = Jalali.fromDateTime(DateTime(d.year, d.month, d.day, 12));
  return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
}

// ─── فیلد تاریخ ───
class JalaliDateField extends StatefulWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool requiredField;
  final bool optionalClear;
  const JalaliDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.requiredField = false,
    this.optionalClear = false,
  });
  @override
  State<JalaliDateField> createState() => _JalaliDateFieldState();
}

class _JalaliDateFieldState extends State<JalaliDateField> {
  late final TextEditingController _c;
  String? _error;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.value == null ? '' : jalaliLabel(widget.value!));
  }

  @override
  void didUpdateWidget(covariant JalaliDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final t = widget.value == null ? '' : jalaliLabel(widget.value!);
      if (_c.text != t) _c.text = t;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  DateTime? _parse(String raw) {
    final latin = NumFmt.toLatinDigits(raw).trim();
    if (latin.isEmpty) return null;
    final parts = latin.split(RegExp(r'[/\-.]'));
    if (parts.length != 3) {
      throw FormatException('فرمت باید YYYY/MM/DD باشد');
    }
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) {
      throw FormatException('اعداد تاریخ نامعتبر است');
    }
    if (y < 1300 || y > 1500) {
      throw FormatException('سال شمسی نامعتبر است');
    }
    if (m < 1 || m > 12) throw FormatException('ماه باید ۱ تا ۱۲ باشد');
    final len = Jalali(y, m, 1).monthLength;
    if (d < 1 || d > len) {
      throw FormatException('روز برای این ماه نامعتبر است (۱–$len)');
    }
    final g = Jalali(y, m, d).toDateTime();
    return DateTime(g.year, g.month, g.day, 12);
  }

  void _applyText() {
    try {
      final v = _parse(_c.text);
      if (v == null && widget.requiredField) {
        setState(() => _error = 'تاریخ الزامی است');
        return;
      }
      setState(() => _error = null);
      widget.onChanged(v);
      if (v != null) _c.text = jalaliLabel(v);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'تاریخ نامعتبر است');
    }
  }

  Future<void> _pick() async {
    final initial = widget.value != null
        ? Jalali.fromDateTime(DateTime(
            widget.value!.year, widget.value!.month, widget.value!.day, 12))
        : Jalali.fromDateTime(DateTime.now());
    final picked =
        await showJalaliDatePicker(context: context, initial: initial);
    if (picked == null) return;
    final g = picked.toDateTime();
    final dt = DateTime(g.year, g.month, g.day, 12);
    setState(() {
      _error = null;
      _c.text = jalaliLabel(dt);
    });
    widget.onChanged(dt);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.datetime,
      style: const TextStyle(fontFamily: 'Vazirmatn'),
      decoration: InputDecoration(
        labelText:
            widget.label + (widget.requiredField ? ' *' : ' (اختیاری)'),
        labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
        hintText: 'مثلاً 1405/08/13',
        hintStyle: const TextStyle(fontFamily: 'Vazirmatn'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        errorText: _error,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.optionalClear && widget.value != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _c.clear();
                  setState(() => _error = null);
                  widget.onChanged(null);
                },
              ),
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: _pick,
            ),
          ],
        ),
      ),
      onEditingComplete: _applyText,
      onSubmitted: (_) => _applyText(),
      onTapOutside: (_) => _applyText(),
    );
  }
}

// ─── صفحه اصلی ───
class ChecksScreen extends StatefulWidget {
  const ChecksScreen({super.key});
  @override
  State<ChecksScreen> createState() => _ChecksScreenState();
}

class _ChecksScreenState extends State<ChecksScreen>
    with SingleTickerProviderStateMixin {
  final _store = CheckStore.instance;
  bool _loading = true;
  late TabController _tabs;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    _init();
  }

  Future<void> _init() async {
    await _store.load();
    await _store.rescheduleAll();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<BankCheck> _filter(List<BankCheck> src) {
    final q = _query.trim();
    if (q.isEmpty) return src;
    final ql = NumFmt.toLatinDigits(q).toLowerCase();
    return src.where((c) {
      final blob = [
        c.personName,
        c.checkNumber ?? '',
        c.sayadId ?? '',
        c.bankName ?? '',
        c.description ?? '',
        c.statusLabel,
      ].join(' ').toLowerCase();
      return blob.contains(q.toLowerCase()) || blob.contains(ql);
    }).toList();
  }

  Future<void> _openForm({BankCheck? existing}) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CheckFormPage(existing: existing)),
    );
    if (ok == true && mounted) setState(() {});
  }

  Future<void> _openDetail(BankCheck c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CheckDetailPage(checkId: c.id)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final rec = _store.received;
    final pay = _store.paid;
    return Column(
      children: [
        if (_store.lastError != null)
          MaterialBanner(
            content: Text(_store.lastError!,
                style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
            actions: [
              TextButton(
                onPressed: () => setState(() => _store.lastError = null),
                child: const Text('باشه',
                    style: TextStyle(fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              _stat(scheme, 'دریافتی', '${rec.length}',
                  NumFmt.format(_store.sumOf(rec).round()), Colors.green),
              const SizedBox(width: 8),
              _stat(scheme, 'پرداختی', '${pay.length}',
                  NumFmt.format(_store.sumOf(pay).round()),
                  Colors.red.shade700),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(children: [
            _chip('امروز', _store.today.length, scheme),
            _chip('آینده', _store.upcoming.length, scheme),
            _chip('گذشته', _store.overdue.length, scheme),
            _chip('برگشتی', _store.bounced.length, scheme),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 26),
                  label: const Text('ثبت چک جدید',
                      style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'Vazirmatn'),
                decoration: InputDecoration(
                  hintText: 'جست‌وجو: نام، شماره، صیاد، بانک…',
                  hintStyle: const TextStyle(
                      fontFamily: 'Vazirmatn', fontSize: 13),
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          labelStyle: const TextStyle(
              fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'همه'),
            Tab(text: 'دریافتی'),
            Tab(text: 'پرداختی'),
            Tab(text: 'امروز'),
            Tab(text: 'آینده'),
            Tab(text: 'گذشته'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _list(_filter(_store.items)),
              _list(_filter(rec)),
              _list(_filter(pay)),
              _list(_filter(_store.today)),
              _list(_filter(_store.upcoming)),
              _list(_filter(_store.overdue)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(ColorScheme scheme, String title, String count, String sum,
      Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w700,
                    color: accent)),
            Text(count,
                style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w900,
                    fontSize: 20)),
            Text('$sum ت',
                style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.65))),
          ],
        ),
      ),
    );
  }

  Widget _chip(String t, int n, ColorScheme scheme) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$t $n',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
        ),
      );

  Widget _list(List<BankCheck> list) {
    if (list.isEmpty) {
      return Center(
        child: Text('چکی در این بخش نیست',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            )),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final c = list[i];
        final col = c.statusColor(Theme.of(context).colorScheme);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _openDetail(c),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: col.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(c.statusLabel,
                            style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: col)),
                      ),
                      const SizedBox(width: 8),
                      Text(c.kind.label,
                          style: const TextStyle(
                              fontFamily: 'Vazirmatn', fontSize: 12)),
                      const Spacer(),
                      Text('${NumFmt.format(c.amount.round())} ت',
                          style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontWeight: FontWeight.w900,
                              fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if ((c.bankName ?? '').trim().isNotEmpty) ...[
                        BankVisual.logo(c.bankName, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(c.personName,
                            style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  Text(
                    'سررسید: ${jalaliLabel(c.dueDate)}'
                    '${c.isOverdue ? ' · گذشته' : c.isDueToday ? ' · امروز' : ''}',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  if (c.isOpen) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        ActionChip(
                          label: Text(
                              c.kind == CheckKind.received
                                  ? 'وصول شد'
                                  : 'پاس شد',
                              style: const TextStyle(fontFamily: 'Vazirmatn')),
                          onPressed: () =>
                              _quickStatus(c, CheckStatus.settled),
                        ),
                        ActionChip(
                          label: const Text('برگشت',
                              style: TextStyle(fontFamily: 'Vazirmatn')),
                          onPressed: () =>
                              _quickStatus(c, CheckStatus.bounced),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _quickStatus(BankCheck c, String status) async {
    final updated = await _store.changeStatus(c, status);
    if (!mounted) return;
    setState(() {});
    // فقط وصول/پاس → پیشنهاد ثبت مالی با تأیید کاربر
    if (status == CheckStatus.settled && updated.linkedExpenseId == null) {
      await askAndLinkFinance(context, updated);
      if (mounted) setState(() {});
    }
  }
}

/// ثبت درآمد/هزینه از چک با زیرساخت ExpenseStore (تکی مشترک)
/// خروجی: id تراکنش یا null در صورت شکست
Future<String?> linkCheckToExpense(BankCheck c) async {
  if (c.linkedExpenseId != null) return c.linkedExpenseId;
  final expId = 'chkexp_${c.id}';
  try {
    final store = ExpenseStore.instance;
    await store.load();
    // جلوگیری از تکرار
    final existing = store.items.where((e) =>
        e.id == expId || (e.note != null && e.note!.contains('ref:${c.id}')));
    if (existing.isNotEmpty) {
      final id = existing.first.id;
      await CheckStore.instance.upsert(c.copyWith(linkedExpenseId: id));
      return id;
    }
    final isIncome = c.kind == CheckKind.received;
    final title = isIncome
        ? 'وصول چک - ${c.personName}'
        : 'پاس چک - ${c.personName}';
    await store.add(Expense(
      id: expId,
      title: title,
      amount: c.amount,
      category: isIncome ? 'سایر درآمد' : 'سایر',
      date: DateTime.now(), // تاریخ واقعی وصول/پاس
      note: 'از چک‌های من · ref:${c.id}',
      isIncome: isIncome,
    ));
    await CheckStore.instance.upsert(c.copyWith(linkedExpenseId: expId));
    return expId;
  } catch (e) {
    debugPrint('linkCheckToExpense: $e');
    rethrow;
  }
}

Future<bool> askAndLinkFinance(BuildContext context, BankCheck c) async {
  if (c.linkedExpenseId != null) return true;
  final isIncome = c.kind == CheckKind.received;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        isIncome ? 'ثبت به‌عنوان درآمد؟' : 'ثبت به‌عنوان هزینه؟',
        style: const TextStyle(fontFamily: 'Vazirmatn'),
      ),
      content: Text(
        isIncome
            ? 'آیا می‌خواهید مبلغ این چک به‌عنوان درآمد در حسابگر من ثبت شود؟\n\n'
                '${NumFmt.format(c.amount.round())} تومان — ${c.personName}'
            : 'آیا می‌خواهید مبلغ این چک به‌عنوان هزینه در حسابگر من ثبت شود؟\n\n'
                '${NumFmt.format(c.amount.round())} تومان — ${c.personName}',
        style: const TextStyle(fontFamily: 'Vazirmatn'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('خیر', style: TextStyle(fontFamily: 'Vazirmatn')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('بله، ثبت شود',
              style: TextStyle(fontFamily: 'Vazirmatn')),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  try {
    await linkCheckToExpense(c);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isIncome ? 'درآمد ثبت شد' : 'هزینه ثبت شد',
          style: const TextStyle(fontFamily: 'Vazirmatn'),
        ),
      ));
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'ثبت مالی ناموفق بود. می‌توانید دوباره تلاش کنید.\n$e',
          style: const TextStyle(fontFamily: 'Vazirmatn'),
        ),
        action: SnackBarAction(
          label: 'تلاش مجدد',
          onPressed: () {
            askAndLinkFinance(context, c);
          },
        ),
      ));
    }
    return false;
  }
}

// ─── فرم ───
class CheckFormPage extends StatefulWidget {
  final BankCheck? existing;
  const CheckFormPage({super.key, this.existing});
  @override
  State<CheckFormPage> createState() => _CheckFormPageState();
}

class _CheckFormPageState extends State<CheckFormPage> {
  late CheckKind _kind;
  final _amount = TextEditingController();
  final _person = TextEditingController();
  final _number = TextEditingController();
  final _sayad = TextEditingController();
  final _bank = TextEditingController();
  final _phone = TextEditingController();
  final _desc = TextEditingController();
  DateTime? _due;
  DateTime? _issue;
  bool _reminders = true;
  final Set<int> _remDays = {7, 3, 1, 0};
  String? _imagePath;
  String? _imagePathBack;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _kind = e.kind;
      _amount.text = NumFmt.format(e.amount.round());
      _person.text = e.personName;
      _number.text = e.checkNumber ?? '';
      final sid = e.sayadId ?? '';
      if (sid.length == 16) {
        _sayad.text =
            '${sid.substring(0, 4)} ${sid.substring(4, 8)} ${sid.substring(8, 12)} ${sid.substring(12, 16)}';
      } else {
        _sayad.text = sid;
      }
      _bank.text = e.bankName ?? '';
      _phone.text = e.phone ?? '';
      _desc.text = e.description ?? '';
      _due = e.dueDate;
      _issue = e.issueDate;
      _reminders = e.remindersEnabled;
      _remDays
        ..clear()
        ..addAll(e.reminderDays);
      _imagePath = e.imagePath;
      _imagePathBack = e.imagePathBack;
    } else {
      _kind = CheckKind.received;
      _due = DateTime.now();
      _reminders = false; // دریافتی: پیش‌فرض خاموش
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _person.dispose();
    _number.dispose();
    _sayad.dispose();
    _bank.dispose();
    _phone.dispose();
    _desc.dispose();
    super.dispose();
  }


  Widget _bankIconWidget() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: BankVisual.logo(_bank.text, size: 28),
    );
  }

  Future<void> _pickImage({required bool back}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('دوربین',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('گالری',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final x = await ImagePicker().pickImage(
        source: source, imageQuality: 85, maxWidth: 1600);
    if (x == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'check_images'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final id = widget.existing?.id ??
        'chk_${DateTime.now().millisecondsSinceEpoch}';
    final suffix = back ? 'back' : 'front';
    final dest = p.join(folder.path, '${id}_$suffix.jpg');
    await File(x.path).copy(dest);
    setState(() {
      if (back) {
        _imagePathBack = dest;
      } else {
        _imagePath = dest;
      }
    });
  }

  Widget _thumb(String? path, String label, VoidCallback onAdd) {
    final has = path != null && File(path).existsSync();
    return Expanded(
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.35)),
          ),
          clipBehavior: Clip.antiAlias,
          child: has
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(path!), fit: BoxFit.cover),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                color: Colors.white,
                                fontSize: 11)),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined, size: 28),
                    const SizedBox(height: 6),
                    Text(label,
                        style: const TextStyle(
                            fontFamily: 'Vazirmatn', fontSize: 12)),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final amount = NumFmt.parse(_amount.text);
    if (amount <= 0) {
      setState(() => _error = 'مبلغ معتبر وارد کنید');
      return;
    }
    if (_due == null) {
      setState(() => _error = 'تاریخ سررسید الزامی است');
      return;
    }
    if (_person.text.trim().isEmpty) {
      setState(() => _error = 'نام شخص الزامی است');
      return;
    }
    final sayadRaw = NumFmt.toLatinDigits(_sayad.text).replaceAll(RegExp(r'\D'), '');
    if (sayadRaw.isNotEmpty && sayadRaw.length != 16) {
      setState(() => _error = 'شناسه صیادی باید دقیقاً ۱۶ رقم باشد');
      return;
    }
    final sayad = sayadRaw;
    setState(() => _saving = true);
    try {
      final id = widget.existing?.id ??
          'chk_${DateTime.now().millisecondsSinceEpoch}';
      final base = widget.existing;
      final check = BankCheck(
        id: id,
        kind: _kind,
        amount: amount,
        dueDate: _due!,
        issueDate: _issue,
        personName: _person.text.trim(),
        checkNumber:
            _number.text.trim().isEmpty ? null : _number.text.trim(),
        sayadId: sayad.isEmpty ? null : sayad,
        bankName: _bank.text.trim().isEmpty ? null : _bank.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        description:
            _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        imagePath: _imagePath,
        imagePathBack: _imagePathBack,
        status: base?.status ?? CheckStatus.pending,
        remindersEnabled: _reminders,
        reminderDays: _remDays.toList()..sort((a, b) => b.compareTo(a)),
        history: base?.history ?? const [],
        linkedExpenseId: base?.linkedExpenseId,
        createdAt: base?.createdAt,
      );
      await CheckStore.instance.upsert(check);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'ذخیره ناموفق: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'ثبت چک' : 'ویرایش چک',
            style: const TextStyle(fontFamily: 'Vazirmatn')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<CheckKind>(
            segments: const [
              ButtonSegment(
                  value: CheckKind.received,
                  label: Text('دریافتی',
                      style: TextStyle(fontFamily: 'Vazirmatn'))),
              ButtonSegment(
                  value: CheckKind.paid,
                  label: Text('پرداختی',
                      style: TextStyle(fontFamily: 'Vazirmatn'))),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() {
              _kind = s.first;
              if (widget.existing == null) {
                // پرداختی: یادآوری روشن / دریافتی: خاموش
                _reminders = _kind == CheckKind.paid;
              }
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            // amounts via NumFmt on save
            inputFormatters: [MoneyInputFormatter()],
            style: const TextStyle(fontFamily: 'Vazirmatn'),
            decoration: InputDecoration(
              labelText: 'مبلغ (تومان) *',
              labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          JalaliDateField(
            label: 'تاریخ سررسید / تاریخ چک',
            value: _due,
            requiredField: true,
            onChanged: (v) => setState(() => _due = v),
          ),
          const SizedBox(height: 12),
          JalaliDateField(
            label: 'تاریخ صدور',
            value: _issue,
            optionalClear: true,
            onChanged: (v) => setState(() => _issue = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _person,
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Vazirmatn'),
            decoration: InputDecoration(
              labelText: _kind == CheckKind.received
                  ? 'نام صادرکننده *'
                  : 'نام دریافت‌کننده *',
              labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Vazirmatn'),
            decoration: InputDecoration(
              labelText: 'شماره چک',
              labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sayad,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [SayadInputFormatter()],
            style: const TextStyle(fontFamily: 'Vazirmatn'),
            decoration: InputDecoration(
              labelText: 'شناسه صیادی (۱۶ رقم)',
              labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
              hintText: 'xxxx xxxx xxxx xxxx',
              hintStyle: const TextStyle(fontFamily: 'Vazirmatn'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bank,
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Vazirmatn'),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'نام بانک',
              labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: _bankIconWidget(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontFamily: 'Vazirmatn'),
            decoration: InputDecoration(
              labelText: 'شماره تماس',
              labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            textAlign: TextAlign.right,
            maxLines: 2,
            style: const TextStyle(fontFamily: 'Vazirmatn'),
            decoration: InputDecoration(
              labelText: 'بابت / توضیحات',
              labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('یادآوری محلی',
                style: TextStyle(fontFamily: 'Vazirmatn')),
            value: _reminders,
            onChanged: (v) => setState(() => _reminders = v),
          ),
          if (_reminders)
            Wrap(
              spacing: 6,
              children: [
                for (final d in [7, 3, 1, 0])
                  FilterChip(
                    label: Text(d == 0 ? 'روز سررسید' : '$d روز قبل',
                        style: const TextStyle(fontFamily: 'Vazirmatn')),
                    selected: _remDays.contains(d),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _remDays.add(d);
                      } else {
                        _remDays.remove(d);
                      }
                    }),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          const Text('تصویر چک',
              style: TextStyle(
                  fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              _thumb(_imagePath, 'روی چک', () => _pickImage(back: false)),
              const SizedBox(width: 10),
              _thumb(_imagePathBack, 'پشت چک', () => _pickImage(back: true)),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50)),
            child: Text(_saving ? 'در حال ذخیره…' : 'ذخیره',
                style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// ─── جزئیات ───
class CheckDetailPage extends StatefulWidget {
  final String checkId;
  const CheckDetailPage({super.key, required this.checkId});
  @override
  State<CheckDetailPage> createState() => _CheckDetailPageState();
}

class _CheckDetailPageState extends State<CheckDetailPage> {
  BankCheck? _c;

  @override
  void initState() {
    super.initState();
    _c = CheckStore.instance.byId(widget.checkId);
  }

  Future<void> _reload() async {
    await CheckStore.instance.load();
    setState(() => _c = CheckStore.instance.byId(widget.checkId));
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('جزئیات چک',
                style: TextStyle(fontFamily: 'Vazirmatn'))),
        body: const Center(
            child: Text('چک پیدا نشد',
                style: TextStyle(fontFamily: 'Vazirmatn'))),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات چک',
            style: TextStyle(fontFamily: 'Vazirmatn')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                    builder: (_) => CheckFormPage(existing: c)),
              );
              if (ok == true) await _reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final yes = await showDialog<Object>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('حذف چک؟',
                      style: TextStyle(fontFamily: 'Vazirmatn')),
                  content: Text(
                    c.linkedExpenseId == null
                        ? 'چک و اعلان‌ها و رویداد تقویم حذف می‌شوند.'
                        : 'چک و اعلان‌ها حذف می‌شوند.\n\nاگر هنگام وصول/پاس، این چک را در هزینه‌ها/درآمد ثبت کرده باشید، آن تراکنش جدا نگه داشته می‌شود مگر گزینه زیر را بزنید.',
                    style: const TextStyle(fontFamily: 'Vazirmatn'),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('انصراف',
                            style: TextStyle(fontFamily: 'Vazirmatn'))),
                    if (c.linkedExpenseId != null)
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, 'all'),
                        child: const Text('حذف چک + تراکنش',
                            style: TextStyle(fontFamily: 'Vazirmatn')),
                      ),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('حذف چک',
                            style: TextStyle(fontFamily: 'Vazirmatn'))),
                  ],
                ),
              );
              if (yes == true || yes == 'all') {
                if (yes == 'all' && c.linkedExpenseId != null) {
                  try {
                    final es = ExpenseStore();
                    await es.load();
                    await es.remove(c.linkedExpenseId!);
                  } catch (e) {
                    debugPrint('remove linked expense: $e');
                  }
                }
                await CheckStore.instance.remove(c.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${NumFmt.format(c.amount.round())} تومان',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.w900,
                  fontSize: 26)),
          const SizedBox(height: 6),
          Text('${c.kind.label} · ${c.statusLabel}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: c.statusColor(scheme),
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _row('شخص', c.personName),
          _row('سررسید', jalaliLabel(c.dueDate)),
          if (c.issueDate != null) _row('صدور', jalaliLabel(c.issueDate!)),
          if (c.checkNumber != null) _row('شماره چک', c.checkNumber!),
          if (c.sayadId != null) _row('صیاد', c.sayadId!),
          if (c.bankName != null) _row('بانک', c.bankName!),
          if (c.phone != null) _row('تماس', c.phone!),
          if (c.description != null) _row('بابت', c.description!),
          if (c.linkedExpenseId != null)
            _row('تراکنش مالی', 'ثبت شده')
          else if (c.status == CheckStatus.settled) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await askAndLinkFinance(context, c);
                await _reload();
              },
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: Text(
                c.kind == CheckKind.received
                    ? 'ثبت به‌عنوان درآمد'
                    : 'ثبت به‌عنوان هزینه',
                style: const TextStyle(fontFamily: 'Vazirmatn'),
              ),
            ),
          ],
          if (c.imagePath != null && File(c.imagePath!).existsSync()) ...[
            const SizedBox(height: 12),
            const Text('روی چک',
                style: TextStyle(
                    fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(c.imagePath!), fit: BoxFit.cover),
            ),
          ],
          if (c.imagePathBack != null &&
              File(c.imagePathBack!).existsSync()) ...[
            const SizedBox(height: 12),
            const Text('پشت چک',
                style: TextStyle(
                    fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(c.imagePathBack!), fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 16),
          const Text('تغییر وضعیت',
              style: TextStyle(
                  fontFamily: 'Vazirmatn', fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in [
                CheckStatus.pending,
                CheckStatus.settled,
                CheckStatus.bounced,
                CheckStatus.transferred,
                CheckStatus.voided,
              ])
                ChoiceChip(
                  label: Text(CheckStatus.label(c.kind, s),
                      style: const TextStyle(fontFamily: 'Vazirmatn')),
                  selected: c.status == s,
                  onSelected: (_) async {
                    String? note;
                    if (s == CheckStatus.transferred ||
                        s == CheckStatus.voided) {
                      final ctrl = TextEditingController();
                      note = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('توضیح (اختیاری)',
                              style: TextStyle(fontFamily: 'Vazirmatn')),
                          content: TextField(
                            controller: ctrl,
                            style: const TextStyle(fontFamily: 'Vazirmatn'),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('بعدی',
                                    style:
                                        TextStyle(fontFamily: 'Vazirmatn'))),
                            FilledButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, ctrl.text.trim()),
                                child: const Text('ثبت',
                                    style:
                                        TextStyle(fontFamily: 'Vazirmatn'))),
                          ],
                        ),
                      );
                    }
                    final updated = await CheckStore.instance
                        .changeStatus(c, s, note: note);
                    if (s == CheckStatus.settled &&
                        updated.linkedExpenseId == null &&
                        mounted) {
                      await askAndLinkFinance(context, updated);
                    }
                    await _reload();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('تاریخچه وضعیت',
              style: TextStyle(
                  fontFamily: 'Vazirmatn', fontWeight: FontWeight.w800)),
          if (c.history.isEmpty)
            const Text('هنوز تغییری ثبت نشده',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13))
          else
            ...c.history.reversed.map((h) => ListTile(
                  dense: true,
                  title: Text(
                    '${CheckStatus.label(c.kind, h.from)} ← ${CheckStatus.label(c.kind, h.to)}',
                    style: const TextStyle(fontFamily: 'Vazirmatn'),
                  ),
                  subtitle: Text(
                    '${jalaliLabel(h.at)} · ${h.at.hour.toString().padLeft(2, '0')}:${h.at.minute.toString().padLeft(2, '0')}'
                    '${h.note != null && h.note!.isNotEmpty ? ' · ${h.note}' : ''}',
                    style: const TextStyle(fontFamily: 'Vazirmatn'),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
                width: 100,
                child: Text(k,
                    style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55)))),
            Expanded(
                child: Text(v,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
