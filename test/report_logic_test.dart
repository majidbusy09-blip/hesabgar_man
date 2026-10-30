import 'package:flutter_test/flutter_test.dart';
import 'package:hesabgar_man/features.dart';

void main() {
  Expense e({
    required String id,
    required double amount,
    required DateTime date,
    bool income = false,
    String category = 'خوراک',
  }) {
    return Expense(
      id: id,
      title: id,
      amount: amount,
      category: category,
      date: date,
      isIncome: income,
    );
  }

  group('ReportLogic', () {
    test('month filter uses Jalali boundaries', () {
      // 1403/01/15 ≈ 2024-04-03
      final items = [
        e(id: '1', amount: 100, date: DateTime(2024, 4, 3)),
        e(id: '2', amount: 50, date: DateTime(2024, 5, 1), income: true),
      ];
      final far = Jalali.fromDateTime(DateTime(2024, 4, 3));
      final m = ReportLogic.inJalaliMonth(items, far.year, far.month);
      expect(m.length, 1);
      expect(ReportLogic.sumExpense(m), 100);
      expect(ReportLogic.sumIncome(m), 0);
      expect(ReportLogic.balance(m), -100);
    });

    test('balance equals income minus expense', () {
      final items = [
        e(id: 'i', amount: 1000, date: DateTime(2024, 1, 1), income: true),
        e(id: 'x', amount: 400, date: DateTime(2024, 1, 2)),
      ];
      expect(ReportLogic.balance(items), 600);
    });

    test('top category and change percent', () {
      final items = [
        e(id: 'a', amount: 100, date: DateTime(2024, 1, 1), category: 'خوراک'),
        e(id: 'b', amount: 300, date: DateTime(2024, 1, 2), category: 'حمل‌ونقل'),
      ];
      expect(ReportLogic.topExpenseCategory(items), 'حمل‌ونقل');
      expect(ReportLogic.expenseChangePercent(120, 100), closeTo(20, 0.001));
      expect(ReportLogic.expenseChangePercent(50, 0), isNull);
    });

    test('all-period sums ignore nothing extra', () {
      final items = [
        e(id: '1', amount: 10, date: DateTime(2020, 1, 1)),
        e(id: '2', amount: 90, date: DateTime(2025, 6, 1), income: true),
      ];
      expect(ReportLogic.sumExpense(items), 10);
      expect(ReportLogic.sumIncome(items), 90);
      expect(ReportLogic.balance(items), 80);
    });
  });
}
