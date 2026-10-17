class CalculatorLogic {
  String _expression = '';
  String _result = '0';

  String get expression => _expression;
  String get result => _result;

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

    _expression += value;
    _result = _expression;
  }

  // قابلیت جدید: پاک کردن آخرین کاراکتر
  void backspace() {
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
      _result = _expression.isEmpty ? '0' : _expression;
    }
  }

  void _calculate() {
    if (_expression.isEmpty) return;
    try {
      double? value = _simpleEvaluate(_expression);
      if (value == null) {
        _result = 'خطا';
      } else if (value == value.roundToDouble()) {
        _result = value.toInt().toString();
      } else {
        _result = value
            .toStringAsFixed(6)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
      }
    } catch (e) {
      _result = 'خطا';
    }
  }

  double? _simpleEvaluate(String expr) {
    expr = expr.replaceAll('×', '*').replaceAll('÷', '/');
    final operators = ['+', '-', '*', '/'];
    for (int i = expr.length - 1; i >= 0; i--) {
      if (operators.contains(expr[i]) && i > 0) {
        final left = double.tryParse(expr.substring(0, i));
        final right = double.tryParse(expr.substring(i + 1));
        if (left != null && right != null) {
          switch (expr[i]) {
            case '+':
              return left + right;
            case '-':
              return left - right;
            case '*':
              return left * right;
            case '/':
              return right == 0 ? null : left / right;
          }
        }
      }
    }
    return double.tryParse(expr);
  }

  bool _isOperator(String s) => ['+', '-', '×', '÷'].contains(s);

  void clear() {
    _expression = '';
    _result = '0';
  }
}
