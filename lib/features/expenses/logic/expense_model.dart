import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
      );

  static const categories = [
    'خوراک',
    'حمل‌ونقل',
    'مسکن',
    'قبوض',
    'سلامت',
    'آموزش',
    'تفریح',
    'پوشاک',
    'سایر',
  ];
}

class ExpenseStore {
  static const _key = 'expenses_v1';
  List<Expense> _items = [];

  List<Expense> get items => List.unmodifiable(_items);

  double get total => _items.fold(0.0, (s, e) => s + e.amount);

  double totalForCategory(String cat) => _items
      .where((e) => e.category == cat)
      .fold(0.0, (s, e) => s + e.amount);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _items = [];
      return;
    }
    final list = jsonDecode(raw) as List;
    _items = list
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> add(Expense expense) async {
    _items.insert(0, expense);
    await _save();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _save();
  }

  Future<void> clear() async {
    _items = [];
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
