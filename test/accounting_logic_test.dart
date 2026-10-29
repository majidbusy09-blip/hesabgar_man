import 'package:flutter_test/flutter_test.dart';
import 'package:hesabgar_man/features.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingLogic acc;

  setUp(() {
    acc = AccountingLogic();
    acc.clearAll();
  });

  void type(String digits) {
    for (final ch in digits.split('')) {
      acc.inputDigit(ch);
    }
  }

  group('AccountingLogic add/sub', () {
    test('100 += 20 yields 120', () {
      type('100');
      acc.plus();
      type('20');
      acc.plus();
      expect(acc.total, 120);
    });

    test('repeat plus uses last operand', () {
      type('50');
      acc.plus(); // total 50
      acc.plus(); // +50 again → 100
      expect(acc.total, 100);
    });

    test('minus reduces total', () {
      type('100');
      acc.plus();
      type('30');
      acc.minus();
      expect(acc.total, 70);
    });
  });

  group('AccountingLogic mul/div pending', () {
    test('100 × 25 = 2500', () {
      type('100');
      acc.multiply();
      type('25');
      acc.totalKey();
      expect(acc.total, 2500);
    });

    test('100 × 25 % = 25', () {
      type('100');
      acc.multiply();
      type('25');
      acc.percent();
      acc.totalKey();
      expect(acc.total, 25);
    });

    test('divide by zero does not crash and leaves safe state', () {
      type('100');
      acc.divide();
      type('0');
      acc.totalKey();
      // implementation clears pending without changing total arbitrarily
      expect(acc.total, isA<double>());
    });
  });
}
