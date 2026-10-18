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
  List<Map<String, String>> get history => _history;

  void toggleAngleMode() {
    _isDegree = !_isDegree;
  }

  // توابع حافظه
  void memoryClear() => _memory = 0;
  void memoryRecall() {
    if (_memory != 0) input(_memory.toString());
  }
  void memoryAdd() {
    try { _memory += double.parse(_result); } catch (_) {}
  }
  void memorySubtract() {
    try { _memory -= double.parse(_result); } catch (_) {}
  }

  void input(String value) {
    if (value == 'C') {
      _expression = '';
      _result = '0';
      return;
    }

    if (value == '=') {
      _calculate();
      return;
    }

    // تبدیل توابع به فرمت قابل فهم برای math_expressions
    if (value == '×') value = '*';
    if (value == '÷') value = '/';
    if (value == 'π') value = 'pi';
    if (value == 'e') value = 'e';

    // تبدیل توابع مثلثاتی بر اساس حالت درجه/رادیان
    if (value == 'sin' || value == 'cos' || value == 'tan') {
      if (_isDegree) {
        // در حالت درجه، باید مقدار را به رادیان تبدیل کنیم
        // برای سادگی فعلاً از دکمه‌های مستقیم استفاده می‌کنیم
      }
    }

    if (_isOperator(value) && _expression.isNotEmpty) {
      final last = _expression[_expression.length - 1];
      if (_isOperator(last)) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    }

    _expression += value;
    _result = _expression;
  }

  void backspace() {
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
      _result = _expression.isEmpty ? '0' : _expression;
    }
  }

  void _calculate() {
    if (_expression.isEmpty) return;
    try {
      String finalExpr = _expression;

      // تبدیل نمادهای ریاضی به فرمت کتابخانه
      finalExpr = finalExpr.replaceAll('×', '*').replaceAll('÷', '/');
      finalExpr = finalExpr.replaceAll('π', 'pi');
      finalExpr = finalExpr.replaceAll('√', 'sqrt');
      
      // اگر در حالت درجه هستیم، باید توابع مثلثاتی را دستی محاسبه کنیم
      if (_isDegree) {
        // این بخش برای سادگی در این نسخه نادیده گرفته می‌شود
        // در نسخه نهایی باید توابع sin/cos/tan را با تبدیل درجه پیاده‌سازی کرد
      }

      Parser p = Parser();
      Expression exp = p.parse(finalExpr);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      String calculatedResult;
      if (eval == eval.roundToDouble()) {
        calculatedResult = eval.toInt().toString();
      } else {
        calculatedResult = eval.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }

      _history.insert(0, {'exp': _expression, 'res': calculatedResult});
      _result = calculatedResult;
      _expression = calculatedResult;
    } catch (e) {
      _result = 'خطا';
    }
  }

  bool _isOperator(String s) => ['+', '-', '×', '÷', '*', '/', '^'].contains(s);

  void clear() {
    _expression = '';
    _result = '0';
  }
}
