import 'package:math_expressions/math_expressions.dart';

class CalculatorLogic {
  String _expression = '';
  String _result = '0';
  final List<Map<String, String>> _history = [];

  String get expression => _expression;
  String get result => _result;
  List<Map<String, String>> get history => _history;

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

    if (_isOperator(value) && _expression.isNotEmpty) {
      final last = _expression[_expression.length - 1];
      if (_isOperator(last)) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    }

    if (value == '×') value = '*';
    if (value == '÷') value = '/';
    
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
      String finalExpr = _expression.replaceAll('×', '*').replaceAll('÷', '/');
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

  bool _isOperator(String s) => ['+', '-', '×', '÷', '*', '/'].contains(s);

  void clear() {
    _expression = '';
    _result = '0';
  }
}
