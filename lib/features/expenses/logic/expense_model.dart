import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/storage/local_store.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final bool isIncome;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.isIncome = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
        'isIncome': isIncome,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String? ?? 'سایر',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        note: json['note'] as String?,
        isIncome: json['isIncome'] as bool? ?? false,
      );

  static const expenseCategories = [
    'خوراک',
    'حمل‌ونقل',
    'مسکن',
    'قبوض',
    'سلامت',
    'آموزش',
    'تفریح',
    'پوشاک',
    'خرید',
    'سایر',
  ];

  static const incomeCategories = [
    'حقوق',
    'فروش',
    'هدیه',
    'سود',
    'سایر درآمد',
  ];
}

class ExpenseStore {
  static const _key = 'expenses_v2';
  List<Expense> _items = [];

  List<Expense> get items => List.unmodifiable(_items);

  List<Expense> get expenses =>
      _items.where((e) => !e.isIncome).toList();
  List<Expense> get incomes =>
      _items.where((e) => e.isIncome).toList();

  double get totalExpense =>
      expenses.fold(0.0, (s, e) => s + e.amount);
  double get totalIncome =>
      incomes.fold(0.0, (s, e) => s + e.amount);
  double get balance => totalIncome - totalExpense;

  List<Expense> forMonth(int year, int month) => _items
      .where((e) => e.date.year == year && e.date.month == month)
      .toList();

  double expenseInMonth(int year, int month) => forMonth(year, month)
      .where((e) => !e.isIncome)
      .fold(0.0, (s, e) => s + e.amount);

  double incomeInMonth(int year, int month) => forMonth(year, month)
      .where((e) => e.isIncome)
      .fold(0.0, (s, e) => s + e.amount);

  Map<String, double> categoryTotals(
      {bool income = false, int? year, int? month}) {
    final map = <String, double>{};
    for (final e in _items) {
      if (e.isIncome != income) continue;
      if (year != null && e.date.year != year) continue;
      if (month != null && e.date.month != month) continue;
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  Future<void> load() async {
    try {
      final store = await LocalStore.instance;
      final raw = store.getString(_key);
      if (raw == null || raw.isEmpty) {
        _items = [];
        return;
      }
      final list = jsonDecode(raw) as List;
      _items = list
          .map((e) {
            try {
              return Expense.fromJson(e as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<Expense>()
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('ExpenseStore load: $e');
      _items = [];
    }
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
    try {
      final store = await LocalStore.instance;
      final raw = jsonEncode(_items.map((e) => e.toJson()).toList());
      await store.setString(_key, raw);
    } catch (e) {
      debugPrint('ExpenseStore save: $e');
    }
  }
}
