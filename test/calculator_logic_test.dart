import 'package:flutter_test/flutter_test.dart';
import 'package:hesabgar_man/features.dart';

void main() {
  late CalculatorLogic calc;

  setUp(() {
    calc = CalculatorLogic();
  });

  double? eval(String expr) {
    calc.clear();
    calc.calculateFromKeyboard(expr);
    if (calc.result.startsWith('خطا')) return null;
    return double.tryParse(calc.result);
  }

  void expectEval(String expr, double expected, {double tol = 1e-9}) {
    final v = eval(expr);
    expect(v, isNotNull, reason: 'expr=$expr result=${calc.result}');
    expect((v! - expected).abs() < tol, isTrue,
        reason: 'expr=$expr got=$v expected=$expected');
  }

  group('basic arithmetic', () {
    test('2+3*4 = 14', () => expectEval('2+3×4', 14));
    test('(2+3)*4 = 20', () => expectEval('(2+3)×4', 20));
    test('2(3+4) = 14', () => expectEval('2(3+4)', 14));
  });

  group('trig DEG/RAD', () {
    test('sin(30) DEG = 0.5', () {
      // default DEG
      expectEval('sin(30)', 0.5, tol: 1e-9);
    });
    test('sin(π/2) RAD ≈ 1', () {
      calc.toggleAngleMode(); // RAD
      expect(calc.angleMode, 'RAD');
      expectEval('sin(π/2)', 1.0, tol: 1e-9);
    });
  });

  group('roots logs factorial', () {
    test('sqrt(81)=9', () => expectEval('√(81)', 9));
    test('cbrt(27)=3', () => expectEval('∛(27)', 3, tol: 1e-9));
    test('log(100)=2', () => expectEval('log(100)', 2));
    test('ln(e)=1', () => expectEval('ln(e)', 1, tol: 1e-9));
    test('5!=120', () => expectEval('5!', 120));
    test('(-3)^2=9', () => expectEval('(-3)^2', 9));
  });

  group('errors', () {
    test('1/0 controlled error', () {
      calc.calculateFromKeyboard('1÷0');
      expect(calc.result.contains('خطا'), isTrue);
      // expression preserved or still accessible
    });
    test('incomplete 2+ no fake result', () {
      calc.input('2');
      calc.input('+');
      expect(calc.livePreview, isEmpty);
    });
  });

  group('percent and unary', () {
    test('50% = 0.5', () => expectEval('50%', 0.5));
    test('200×50% = 100', () => expectEval('200×50%', 100));
  });

  group('memory', () {
    test('M+ MR', () {
      calc.calculateFromKeyboard('10');
      calc.memoryAdd();
      calc.clear();
      calc.memoryRecall();
      calc.calculate();
      expect(double.tryParse(calc.result), 10);
    });
  });

  group('CalcNum formatting (stage 3)', () {
    test('integer display', () {
      expect(CalcNum.format(14.0), '14');
      expect(CalcNum.format(0.0), '0');
    });
    test('strip trailing zeros', () {
      expect(CalcNum.format(1.5), '1.5');
      expect(CalcNum.format(0.5), '0.5');
    });
    test('scientific large', () {
      final s = CalcNum.format(1.5e15);
      expect(s.contains('e'), isTrue);
    });
    test('scientific small', () {
      final s = CalcNum.format(1.5e-8);
      expect(s.contains('e'), isTrue);
    });
    test('parse scientific roundtrip', () {
      final v = 1.2345e12;
      final s = CalcNum.format(v);
      final back = CalcNum.parse(s);
      expect(back, isNotNull);
      expect((back! - v).abs() / v < 1e-9, isTrue);
    });
    test('lastValue keeps precision for memory', () {
      calc.calculateFromKeyboard('1÷3');
      calc.memoryAdd();
      calc.clear();
      calc.memoryRecall();
      calc.calculate();
      // should be close to 1/3 not truncated display artifact only
      final v = double.tryParse(calc.result);
      expect(v, isNotNull);
      expect((v! - 1 / 3).abs() < 1e-12, isTrue);
    });
  });

  group('persian digits in formula', () {
    test('۱۲+۳ = 15', () {
      calc.clear();
      calc.calculateFromKeyboard('۱۲+۳');
      final v = double.tryParse(calc.result.replaceAll(',', ''));
      expect(v, 15);
    });
  });

  group('inverse trig DEG', () {
    test('asin(0.5) DEG ≈ 30', () {
      // default DEG
      expectEval('asin(0.5)', 30, tol: 1e-6);
    });
    test('acos(0.5) DEG ≈ 60', () {
      expectEval('acos(0.5)', 60, tol: 1e-6);
    });
  });
}
