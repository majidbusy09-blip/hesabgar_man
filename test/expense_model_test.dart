import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hesabgar_man/features.dart';

void main() {
  group('Expense JSON round-trip', () {
    test('toJson/fromJson preserves fields', () {
      final original = Expense(
        id: 'e1',
        title: 'نان',
        amount: 85000,
        category: 'خوراک',
        date: DateTime.utc(2024, 5, 10, 12),
        note: 'صبحانه',
        isIncome: false,
      );
      final decoded = Expense.fromJson(original.toJson());
      expect(decoded.id, original.id);
      expect(decoded.title, original.title);
      expect(decoded.amount, original.amount);
      expect(decoded.category, original.category);
      expect(decoded.note, original.note);
      expect(decoded.isIncome, original.isIncome);
      expect(decoded.date.toIso8601String(), original.date.toIso8601String());
    });

    test('list encode/decode like ExpenseStore payload', () {
      final items = [
        Expense(
          id: 'a',
          title: 'حقوق',
          amount: 50000000,
          category: 'حقوق',
          date: DateTime.utc(2024, 1, 1),
          isIncome: true,
        ),
        Expense(
          id: 'b',
          title: 'مترو',
          amount: 20000,
          category: 'حمل‌ونقل',
          date: DateTime.utc(2024, 1, 2),
        ),
      ];
      final raw = jsonEncode(items.map((e) => e.toJson()).toList());
      final list = jsonDecode(raw) as List;
      final restored = list
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(restored.length, 2);
      expect(restored[0].isIncome, isTrue);
      expect(restored[1].amount, 20000);
    });

    test('missing category defaults to سایر', () {
      final e = Expense.fromJson({
        'id': 'x',
        'title': 't',
        'amount': 10,
        'date': '2024-01-01T00:00:00.000Z',
      });
      expect(e.category, 'سایر');
      expect(e.isIncome, isFalse);
    });

    test('corrupt amount type throws', () {
      expect(
        () => Expense.fromJson({
          'id': 'x',
          'title': 't',
          'amount': 'not-a-number',
          'date': '2024-01-01T00:00:00.000Z',
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
