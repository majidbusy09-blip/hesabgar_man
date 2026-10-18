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
      calculateFromKeyboard(_expression); // محاسبه فرمول فعلی
      return;
    }

    if (value == '×') value = '*';
    if (value == '÷') value = '/';
    
    if (_isOperator(value) && _expression.isNotEmpty) {
      final last = _expression[_expression.length - 1];
      if (_isOperator(last)) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    }

    _expression += value;
    _result = _expression;
  }

  // تابع جدید: محاسبه فرمولی که کاربر با کیبورد تایپ کرده
  void calculateFromKeyboard(String formula) {
    if (formula.trim().isEmpty) return;
    try {
      // تبدیل نمادهای فارسی/عربی به استاندارد
      String finalExpr = formula
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', 'pi')
          .replaceAll('√', 'sqrt');

      Parser p = Parser();
      Expression exp = p.parse(finalExpr);
      ContextModel cm = ContextModel();
      
      // برای پشتیبانی از توابع مثلثاتی (در این نسخه ساده، رادیان محاسبه می‌شود)
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      String calculatedResult;
      if (eval == eval.roundToDouble()) {
        calculatedResult = eval.toInt().toString();
      } else {
        calculatedResult = eval.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }

      _history.insert(0, {'exp': formula, 'res': calculatedResult});
      _result = calculatedResult;
      _expression = calculatedResult;
    } catch (e) {
      _result = 'خطا در فرمول';
    }
  }

  void backspace() {
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
      _result = _expression.isEmpty ? '0' : _expression;
    }
  }

  bool _isOperator(String s) => ['+', '-', '×', '÷', '*', '/', '^'].contains(s);

  void clear() {
    _expression = '';
    _result = '0';
  }
}
