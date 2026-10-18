import 'dart:math' as math;
import 'package:math_expressions/math_expressions.dart';

class CalculatorLogic {
  String _expression = '';
  String _result = '0';
  double _memory = 0;
  bool _isDegree = true;
  final List<Map<String, String>> _history = [];

  String get expression => _expression;
  String get result => _result;
  String get memoryDisplay => _memory != 0 ? 'M' : '';
  String get angleMode => _isDegree ? 'DEG' : 'RAD';
  List<Map<String, String>> get history => List.unmodifiable(_history);

  void toggleAngleMode() {
    _isDegree = !_isDegree;
  }

  void memoryClear() => _memory = 0;

  void memoryRecall() {
    if (_memory != 0) {
      _expression += _formatNumber(_memory);
      _result = _expression;
    }
  }

  void memoryAdd() {
    try {
      _memory += double.parse(_result);
    } catch (_) {}
  }

  void memorySubtract() {
    try {
      _memory -= double.parse(_result);
    } catch (_) {}
  }

  void input(String value) {
    if (value == 'C') {
      clear();
      return;
    }

    if (value == '=') {
      calculate();
      return;
    }

    // توابع علمی که پرانتز باز می‌کنند
    const functions = {
      'sin': 'sin(',
      'cos': 'cos(',
      'tan': 'tan(',
      'ln': 'ln(',
      'log': 'log(',
      '√': 'sqrt(',
    };

    if (functions.containsKey(value)) {
      _expression += functions[value]!;
      _result = _expression;
      return;
    }

    // عملیات ویژه
    if (value == 'x²') {
      _expression += '^2';
      _result = _expression;
      return;
    }

    if (value == '1/x') {
      if (_expression.isEmpty) {
        _expression = '1/';
      } else {
        _expression = '1/($_expression)';
      }
      _result = _expression;
      return;
    }

    if (value == '%') {
      _expression += '/100';
      _result = _expression;
      return;
    }

    if (value == '!') {
      _expression += '!';
      _result = _expression;
      return;
    }

    if (value == 'π') {
      _expression += 'π';
      _result = _expression;
      return;
    }

    if (value == 'e') {
      _expression += 'e';
      _result = _expression;
      return;
    }

    // عملگرها
    String op = value;
    if (value == '×') op = '×';
    if (value == '÷') op = '÷';

    if (_isOperator(op) && _expression.isNotEmpty) {
      final last = _expression[_expression.length - 1];
      if (_isOperator(last)) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    }

    _expression += op;
    _result = _expression;
  }

  void calculate() {
    if (_expression.trim().isEmpty) return;
    calculateFromKeyboard(_expression);
  }

  void calculateFromKeyboard(String formula) {
    if (formula.trim().isEmpty) return;

    try {
      String expr = formula
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '(pi)')
          .replaceAll('√', 'sqrt');

      // ln → log (طبیعی در math_expressions)
      // log → log(x)/log(10) برای پایه ۱۰
      expr = expr.replaceAllMapped(
        RegExp(r'log\(([^()]+)\)'),
        (m) => '(log(${m[1]})/log(10))',
      );
      expr = expr.replaceAll('ln(', 'log(');

      // تبدیل ! به فاکتوریل (فقط برای اعداد ساده)
      expr = _replaceFactorial(expr);

      // پشتیبانی از DEG: تبدیل آرگومان توابع مثلثاتی
      if (_isDegree) {
        expr = _convertTrigToDegree(expr);
      }

      // e به عنوان ثابت
      expr = expr.replaceAllMapped(
        RegExp(r'(?<![a-zA-Z])e(?![a-zA-Z(])'),
        (_) => '(e)',
      );

      final p = Parser();
      final exp = p.parse(expr);
      final cm = ContextModel();
      cm.bindVariableName('e', Number(math.e));

      final eval = exp.evaluate(EvaluationType.REAL, cm);
      final calculatedResult = _formatNumber(eval);

      _history.insert(0, {'exp': formula, 'res': calculatedResult});
      if (_history.length > 50) _history.removeLast();

      _result = calculatedResult;
      _expression = calculatedResult;
    } catch (e) {
      _result = 'خطا';
    }
  }

  /// تبدیل sin(x) به sin(x * pi / 180) وقتی حالت DEG است
  String _convertTrigToDegree(String expr) {
    const funcs = ['sin', 'cos', 'tan'];
    for (final f in funcs) {
      expr = expr.replaceAllMapped(
        RegExp('$f\\(([^()]+)\\)'),
        (m) => '$f((${m[1]}) * pi / 180)',
      );
    }
    return expr;
  }

  /// جایگزینی ساده n! با فاکتوریل
  String _replaceFactorial(String expr) {
    return expr.replaceAllMapped(
      RegExp(r'(\d+)!'),
      (m) {
        final n = int.tryParse(m[1]!) ?? 0;
        if (n < 0 || n > 20) return m[0]!;
        return _factorial(n).toString();
      },
    );
  }

  int _factorial(int n) {
    if (n <= 1) return 1;
    int r = 1;
    for (int i = 2; i <= n; i++) {
      r *= i;
    }
    return r;
  }

  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return 'خطا';
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(8)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void backspace() {
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
      _result = _expression.isEmpty ? '0' : _expression;
    }
  }

  bool _isOperator(String s) =>
      ['+', '-', '×', '÷', '*', '/', '^'].contains(s);

  void clear() {
    _expression = '';
    _result = '0';
  }

  void clearHistory() => _history.clear();
}
