import 'dart:math' as math;
import 'package:math_expressions/math_expressions.dart';

class CalculatorLogic {
  String _expression = '';
  String _result = '0';
  String _livePreview = '';
  double _memory = 0;
  bool _isDegree = true;
  int _openParens = 0;
  final List<Map<String, String>> _history = [];

  String get expression => _expression;
  String get result => _result;
  String get livePreview => _livePreview;
  String get memoryDisplay => _memory != 0 ? 'M' : '';
  String get angleMode => _isDegree ? 'DEG' : 'RAD';
  List<Map<String, String>> get history => List.unmodifiable(_history);

  void toggleAngleMode() => _isDegree = !_isDegree;

  void memoryClear() => _memory = 0;

  void memoryRecall() {
    if (_memory != 0) _appendToken(_formatNumber(_memory));
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

  void toggleParen() {
    if (_openParens > 0 && !_needsOpenParen()) {
      _expression += ')';
      _openParens--;
    } else {
      _maybeImplicitMul();
      _expression += '(';
      _openParens++;
    }
    _syncDisplay();
  }

  bool _needsOpenParen() {
    if (_expression.isEmpty) return true;
    final last = _expression[_expression.length - 1];
    return _isOperator(last) || last == '(';
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
    if (value == '()') {
      toggleParen();
      return;
    }
    if (value == '+/-') {
      _toggleSign();
      return;
    }

    const functions = {
      'sin': 'sin(',
      'cos': 'cos(',
      'tan': 'tan(',
      'asin': 'asin(',
      'acos': 'acos(',
      'atan': 'atan(',
      'ln': 'ln(',
      'log': 'log(',
      '√': 'sqrt(',
      '∛': 'cbrt(',
      'abs': 'abs(',
      'exp': 'exp(',
    };

    if (functions.containsKey(value)) {
      _maybeImplicitMul();
      _expression += functions[value]!;
      _openParens++;
      _syncDisplay();
      return;
    }

    if (value == 'x²') {
      _expression += '^2';
      _syncDisplay();
      return;
    }
    if (value == 'x³') {
      _expression += '^3';
      _syncDisplay();
      return;
    }
    if (value == '10ˣ') {
      _maybeImplicitMul();
      _expression += '10^(';
      _openParens++;
      _syncDisplay();
      return;
    }
    if (value == 'eˣ') {
      _maybeImplicitMul();
      _expression += 'exp(';
      _openParens++;
      _syncDisplay();
      return;
    }
    if (value == '1/x') {
      if (_expression.isEmpty || _result == '0') {
        _expression = '1/';
      } else {
        _expression = '1/($_expression)';
        _openParens = 0;
      }
      _syncDisplay();
      return;
    }
    if (value == '%') {
      _expression += '/100';
      _syncDisplay();
      return;
    }
    if (value == '!') {
      _expression += '!';
      _syncDisplay();
      return;
    }
    if (value == 'π') {
      _maybeImplicitMul();
      _expression += 'π';
      _syncDisplay();
      return;
    }
    if (value == 'e') {
      _maybeImplicitMul();
      _expression += 'e';
      _syncDisplay();
      return;
    }
    if (value == '(') {
      _maybeImplicitMul();
      _expression += '(';
      _openParens++;
      _syncDisplay();
      return;
    }
    if (value == ')') {
      if (_openParens > 0) {
        _expression += ')';
        _openParens--;
        _syncDisplay();
      }
      return;
    }

    if (_isOperator(value)) {
      if (_expression.isEmpty) {
        if (value == '-') {
          _expression = '-';
          _syncDisplay();
        }
        return;
      }
      final last = _expression[_expression.length - 1];
      if (_isOperator(last)) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
      if (last == '(' && value != '-') return;
      _expression += value;
      _syncDisplay();
      return;
    }

    if (value == '.') {
      if (!_canAddDot()) return;
    }
    _expression += value;
    _syncDisplay();
  }

  void _appendToken(String token) {
    _maybeImplicitMul();
    _expression += token;
    _syncDisplay();
  }

  void _maybeImplicitMul() {
    if (_expression.isEmpty) return;
    final last = _expression[_expression.length - 1];
    if (RegExp(r'[0-9)πe!]').hasMatch(last)) {
      _expression += '×';
    }
  }

  bool _canAddDot() {
    final parts = _expression.split(RegExp(r'[+\-×÷*/^()]'));
    final last = parts.isEmpty ? '' : parts.last;
    return !last.contains('.');
  }

  void _toggleSign() {
    if (_expression.isEmpty) {
      _expression = '-';
      _syncDisplay();
      return;
    }
    final match =
        RegExp(r'([+\-×÷*/^]?)(\d+\.?\d*)$').firstMatch(_expression);
    if (match != null) {
      final op = match.group(1) ?? '';
      final num = match.group(2)!;
      final start = match.start;
      if (op == '-') {
        _expression = '${_expression.substring(0, start)}+$num';
      } else if (op == '+') {
        _expression = '${_expression.substring(0, start)}-$num';
      } else if (op.isEmpty && start == 0) {
        _expression = '-$_expression';
      } else {
        _expression = '${_expression.substring(0, start)}$op(-$num)';
      }
      _syncDisplay();
    }
  }

  void _syncDisplay() {
    if (_expression.isEmpty) {
      _result = '0';
      _livePreview = '';
      return;
    }
    _result = _expression;
    _livePreview = _tryEvaluatePreview(_expression) ?? '';
  }

  /// نتیجه زنده — بدون ذخیره در تاریخچه
  String? _tryEvaluatePreview(String formula) {
    try {
      var expr = formula;
      var open = _openParens;
      while (open > 0) {
        expr += ')';
        open--;
      }
      // اگر به عملگر ختم شود قابل محاسبه نیست
      if (expr.isEmpty) return null;
      final last = expr[expr.length - 1];
      if (_isOperator(last) || last == '(') return null;

      final value = _evaluateRaw(expr);
      if (value == null) return null;
      return _formatNumber(value);
    } catch (_) {
      return null;
    }
  }

  double? _evaluateRaw(String formula) {
    try {
      String expr = formula
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '(${math.pi})')
          .replaceAll('√', 'sqrt')
          .replaceAll('∛', 'cbrt');

      expr = expr.replaceAllMapped(
        RegExp(r'(?<![a-zA-Z])e(?![a-zA-Z0-9(])'),
        (_) => '(${math.e})',
      );

      // cbrt(x) → (x)^(1/3)
      expr = expr.replaceAllMapped(
        RegExp(r'cbrt\(([^()]+)\)'),
        (m) => '((${m[1]})^(1/3))',
      );

      // abs
      expr = expr.replaceAllMapped(
        RegExp(r'abs\(([^()]+)\)'),
        (m) => 'abs(${m[1]})',
      );

      // log10 و ln
      expr = expr.replaceAllMapped(
        RegExp(r'log\(([^()]+)\)'),
        (m) => '(log(${m[1]})/log(10))',
      );
      expr = expr.replaceAll('ln(', 'log(');

      // exp
      expr = expr.replaceAllMapped(
        RegExp(r'exp\(([^()]+)\)'),
        (m) => 'e^(${m[1]})',
      );
      // بعد از exp ممکن است e دوباره آمده باشد
      expr = expr.replaceAllMapped(
        RegExp(r'(?<![a-zA-Z0-9.])e(?=\^)'),
        (_) => '(${math.e})',
      );

      expr = _replaceFactorial(expr);

      if (_isDegree) {
        expr = _convertTrigToDegree(expr);
      }

      final p = Parser();
      final exp = p.parse(expr);
      final cm = ContextModel();
      final eval = exp.evaluate(EvaluationType.REAL, cm);
      if (eval is! num || eval.isNaN || eval.isInfinite) return null;
      return eval.toDouble();
    } catch (_) {
      return null;
    }
  }

  void calculate() {
    if (_expression.trim().isEmpty) return;
    var expr = _expression;
    while (_openParens > 0) {
      expr += ')';
      _openParens--;
    }
    final value = _evaluateRaw(expr);
    if (value == null) {
      _result = 'خطا';
      _livePreview = '';
      return;
    }
    final calculatedResult = _formatNumber(value);
    _history.insert(0, {'exp': expr, 'res': calculatedResult});
    if (_history.length > 50) _history.removeLast();
    _result = calculatedResult;
    _expression = calculatedResult;
    _livePreview = '';
    _openParens = 0;
  }

  void calculateFromKeyboard(String formula) {
    if (formula.trim().isEmpty) return;
    _expression = formula;
    _openParens = 0;
    // شمارش پرانتز
    for (final ch in formula.split('')) {
      if (ch == '(') _openParens++;
      if (ch == ')' && _openParens > 0) _openParens--;
    }
    calculate();
  }

  String _convertTrigToDegree(String expr) {
    for (final f in ['sin', 'cos', 'tan']) {
      expr = expr.replaceAllMapped(
        RegExp('$f\\(([^()]+)\\)'),
        (m) => '$f((${m[1]})*${math.pi}/180)',
      );
    }
    // معکوس‌ها خروجی را از رادیان به درجه
    for (final f in ['asin', 'acos', 'atan']) {
      expr = expr.replaceAllMapped(
        RegExp('$f\\(([^()]+)\\)'),
        (m) => '(($f(${m[1]}))*180/${math.pi})',
      );
    }
    return expr;
  }

  String _replaceFactorial(String expr) {
    return expr.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
      final n = int.tryParse(m[1]!) ?? 0;
      if (n < 0 || n > 20) return m[0]!;
      return _factorial(n).toString();
    });
  }

  int _factorial(int n) {
    if (n <= 1) return 1;
    var r = 1;
    for (var i = 2; i <= n; i++) {
      r *= i;
    }
    return r;
  }

  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return 'خطا';
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    var s = value.toStringAsFixed(10);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  void backspace() {
    if (_expression.isEmpty) return;
    final last = _expression[_expression.length - 1];
    if (last == '(') _openParens = (_openParens - 1).clamp(0, 99);
    if (last == ')') _openParens++;
    _expression = _expression.substring(0, _expression.length - 1);
    _syncDisplay();
  }

  bool _isOperator(String s) =>
      ['+', '-', '×', '÷', '*', '/', '^'].contains(s);

  void clear() {
    _expression = '';
    _result = '0';
    _livePreview = '';
    _openParens = 0;
  }

  void clearHistory() => _history.clear();
}
