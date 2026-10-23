// ===== features.dart — screens & logic =====
import 'core.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;


// ---------- features/calculator/logic/calculator_logic.dart ----------
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

// ---------- features/calculator/presentation/widgets/calc_button.dart ----------
class CalcButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOperator;
  final bool isEqual;
  final bool isScientific;
  final bool isMemory;

  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isOperator = false,
    this.isEqual = false,
    this.isScientific = false,
    this.isMemory = false,
  });

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    _controller.forward();
    // ویبره مستقیم + از Provider
    try {
      Feedback.forTap(context);
    } catch (_) {}
    try {
      if (widget.isEqual) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
      HapticFeedback.vibrate();
    } catch (_) {}
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
    try {
      final fb = Provider.of<FeedbackProvider>(context, listen: false);
      fb.playTap(strong: widget.isEqual);
    } catch (_) {}
  }

  void _release() {
    _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    Color bgColor;
    Color textColor;

    if (widget.isEqual) {
      bgColor = scheme.primary;
      textColor = scheme.onPrimary;
    } else if (widget.isOperator) {
      bgColor = scheme.secondary;
      textColor = scheme.onSecondary;
    } else if (widget.isMemory) {
      bgColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0);
      textColor = isDark ? Colors.amber : Colors.brown;
    } else if (widget.isScientific) {
      bgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);
      textColor = isDark ? Colors.white70 : Colors.black87;
    } else {
      bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      textColor = isDark ? Colors.white : Colors.black87;
    }

    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        elevation: widget.isEqual ? 2 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTapDown: (_) => _press(),
          onTapUp: (_) => _release(),
          onTapCancel: () => _controller.reverse(),
          child: Container(
            margin: const EdgeInsets.all(1.5),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize:
                        widget.isScientific || widget.isMemory ? 12 : 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- features/converter/logic/unit_data.dart ----------
class UnitItem {
  final String id;
  final String name;
  final double toBase; // ضریب تبدیل به واحد پایه
  final double Function(double)? customToBase;
  final double Function(double)? customFromBase;

  const UnitItem(this.id, this.name, this.toBase, {this.customToBase, this.customFromBase});
}

class UnitCategory {
  final String id;
  final String name;
  final String emoji;
  final List<UnitItem> units;

  const UnitCategory(this.id, this.name, this.emoji, this.units);
}

class UnitData {
  static final categories = <UnitCategory>[
    UnitCategory('length', 'طول', '📏', [
      UnitItem('m', 'متر', 1),
      UnitItem('km', 'کیلومتر', 1000),
      UnitItem('cm', 'سانتی‌متر', 0.01),
      UnitItem('mm', 'میلی‌متر', 0.001),
      UnitItem('mi', 'مایل', 1609.344),
      UnitItem('yd', 'یارد', 0.9144),
      UnitItem('ft', 'فوت', 0.3048),
      UnitItem('in', 'اینچ', 0.0254),
    ]),
    UnitCategory('area', 'سطح', '⬜', [
      UnitItem('m2', 'متر مربع', 1),
      UnitItem('km2', 'کیلومتر مربع', 1e6),
      UnitItem('ha', 'هکتار', 10000),
      UnitItem('acre', 'جریب (Acre)', 4046.856),
      UnitItem('ft2', 'فوت مربع', 0.092903),
      UnitItem('cm2', 'سانتی‌متر مربع', 0.0001),
    ]),
    UnitCategory('volume', 'حجم', '🧪', [
      UnitItem('l', 'لیتر', 1),
      UnitItem('ml', 'میلی‌لیتر', 0.001),
      UnitItem('m3', 'متر مکعب', 1000),
      UnitItem('gal', 'گالن (US)', 3.78541),
      UnitItem('qt', 'کوارت', 0.946353),
      UnitItem('cup', 'فنجان', 0.236588),
    ]),
    UnitCategory('mass', 'جرم', '⚖️', [
      UnitItem('kg', 'کیلوگرم', 1),
      UnitItem('g', 'گرم', 0.001),
      UnitItem('mg', 'میلی‌گرم', 1e-6),
      UnitItem('t', 'تن', 1000),
      UnitItem('lb', 'پوند', 0.453592),
      UnitItem('oz', 'اونس', 0.0283495),
    ]),
    UnitCategory('temp', 'دما', '🌡️', [
      UnitItem('c', 'سلسیوس', 1,
          customToBase: (v) => v,
          customFromBase: (v) => v),
      UnitItem('f', 'فارنهایت', 1,
          customToBase: (v) => (v - 32) * 5 / 9,
          customFromBase: (v) => v * 9 / 5 + 32),
      UnitItem('k', 'کلوین', 1,
          customToBase: (v) => v - 273.15,
          customFromBase: (v) => v + 273.15),
    ]),
    UnitCategory('speed', 'سرعت', '🚀', [
      UnitItem('mps', 'متر بر ثانیه', 1),
      UnitItem('kmh', 'کیلومتر بر ساعت', 1 / 3.6),
      UnitItem('mph', 'مایل بر ساعت', 0.44704),
      UnitItem('knot', 'گره', 0.514444),
    ]),
    UnitCategory('time', 'زمان', '⏱️', [
      UnitItem('s', 'ثانیه', 1),
      UnitItem('min', 'دقیقه', 60),
      UnitItem('h', 'ساعت', 3600),
      UnitItem('day', 'روز', 86400),
      UnitItem('week', 'هفته', 604800),
      UnitItem('ms', 'میلی‌ثانیه', 0.001),
    ]),
    UnitCategory('data', 'داده', '💾', [
      UnitItem('b', 'بایت', 1),
      UnitItem('kb', 'کیلوبایت', 1024),
      UnitItem('mb', 'مگابایت', 1048576),
      UnitItem('gb', 'گیگابایت', 1073741824),
      UnitItem('tb', 'ترابایت', 1099511627776),
      UnitItem('bit', 'بیت', 0.125),
    ]),
    UnitCategory('pressure', 'فشار', '💨', [
      UnitItem('pa', 'پاسکال', 1),
      UnitItem('kpa', 'کیلوپاسکال', 1000),
      UnitItem('bar', 'بار', 100000),
      UnitItem('atm', 'اتمسفر', 101325),
      UnitItem('psi', 'PSI', 6894.76),
      UnitItem('mmhg', 'میلی‌متر جیوه', 133.322),
    ]),
    UnitCategory('energy', 'انرژی', '⚡', [
      UnitItem('j', 'ژول', 1),
      UnitItem('kj', 'کیلوژول', 1000),
      UnitItem('cal', 'کالری', 4.184),
      UnitItem('kcal', 'کیلوکالری', 4184),
      UnitItem('wh', 'وات‌ساعت', 3600),
      UnitItem('kwh', 'کیلووات‌ساعت', 3600000),
    ]),
    UnitCategory('angle', 'زاویه', '📐', [
      UnitItem('deg', 'درجه', 1),
      UnitItem('rad', 'رادیان', 57.2957795),
      UnitItem('grad', 'گراد', 0.9),
    ]),
  ];

  static double convert({
    required UnitCategory category,
    required UnitItem from,
    required UnitItem to,
    required double value,
  }) {
    if (from.id == to.id) return value;

    // دما واحد پایه = سلسیوس
    if (category.id == 'temp') {
      final celsius = from.customToBase != null
          ? from.customToBase!(value)
          : value;
      return to.customFromBase != null
          ? to.customFromBase!(celsius)
          : celsius;
    }

    final base = value * from.toBase;
    return base / to.toBase;
  }
}

// ---------- features/converter/presentation/converter_screen.dart ----------
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  late UnitCategory _category;
  late UnitItem _from;
  late UnitItem _to;
  final _controller = TextEditingController(text: '1');
  double _result = 0;

  @override
  void initState() {
    super.initState();
    _category = UnitData.categories.first;
    _from = _category.units.first;
    _to = _category.units.length > 1
        ? _category.units[1]
        : _category.units.first;
    _recalc();
    _controller.addListener(_recalc);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _recalc() {
    final v = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;
    setState(() {
      _result = UnitData.convert(
        category: _category,
        from: _from,
        to: _to,
        value: v,
      );
    });
  }

  void _swap() {
    setState(() {
      final t = _from;
      _from = _to;
      _to = t;
    });
    _recalc();
  }

  void _selectCategory(UnitCategory c) {
    setState(() {
      _category = c;
      _from = c.units.first;
      _to = c.units.length > 1 ? c.units[1] : c.units.first;
    });
    _recalc();
  }

  String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return '—';
    if (v == 0) return '0';
    if (v.abs() >= 1e10 || (v.abs() < 1e-6 && v != 0)) {
      return v.toStringAsExponential(6);
    }
    var s = v.toStringAsFixed(8);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('مبدل واحد')),
      body: Column(
        children: [
          // دسته‌ها
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: UnitData.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = UnitData.categories[i];
                final selected = c.id == _category.id;
                return ChoiceChip(
                  label: Text(
                    '${c.emoji} ${c.name}',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      color: selected ? scheme.onPrimary : null,
                    ),
                  ),
                  selected: selected,
                  selectedColor: scheme.primary,
                  onSelected: (_) => _selectCategory(c),
                );
              },
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // از
                _unitCard(
                  title: 'از',
                  unit: _from,
                  units: _category.units,
                  onUnitChanged: (u) {
                    setState(() => _from = u);
                    _recalc();
                  },
                  child: TextField(
                    controller: _controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
                    ],
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                  ),
                ),

                // جابه‌جایی
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: IconButton.filledTonal(
                      onPressed: _swap,
                      icon: const Icon(Icons.swap_vert, size: 28),
                      tooltip: 'جابه‌جایی',
                    ),
                  ),
                ),

                // به
                _unitCard(
                  title: 'به',
                  unit: _to,
                  units: _category.units,
                  onUnitChanged: (u) {
                    setState(() => _to = u);
                    _recalc();
                  },
                  child: Text(
                    _fmt(_result),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // جدول سریع همه واحدها
                Text(
                  'همهٔ واحدهای ${_category.name}',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                ..._category.units.map((u) {
                  final v = double.tryParse(
                          _controller.text.replaceAll(',', '.')) ??
                      0;
                  final converted = UnitData.convert(
                    category: _category,
                    from: _from,
                    to: u,
                    value: v,
                  );
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      title: Text(u.name,
                          style: const TextStyle(fontFamily: 'Vazirmatn')),
                      trailing: Text(
                        _fmt(converted),
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        setState(() => _to = u);
                        _recalc();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitCard({
    required String title,
    required UnitItem unit,
    required List<UnitItem> units,
    required ValueChanged<UnitItem> onUnitChanged,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        color: Colors.grey)),
                const Spacer(),
                DropdownButton<UnitItem>(
                  value: unit,
                  underline: const SizedBox.shrink(),
                  items: units
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u.name,
                                style:
                                    const TextStyle(fontFamily: 'Vazirmatn')),
                          ))
                      .toList(),
                  onChanged: (u) {
                    if (u != null) onUnitChanged(u);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------- features/compound/logic/compound_math.dart ----------
/// جمع و تفریق اعداد مرکب (مخصوص دانش‌آموزان)
/// مثال: ۲ ساعت و ۴۵ دقیقه + ۱ ساعت و ۳۰ دقیقه

class CompoundUnitDef {
  final String name;
  final int base; // نسبت به واحد کوچک‌تر بعدی (مثلاً دقیقه=60 ثانیه)
  const CompoundUnitDef(this.name, this.base);
}

class CompoundSystem {
  final String id;
  final String title;
  final String emoji;
  final List<CompoundUnitDef> units; // از بزرگ به کوچک

  const CompoundSystem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.units,
  });

  /// تبدیل لیست مقادیر (هم‌اندازه units) به کوچک‌ترین واحد
  int toSmallest(List<int> values) {
    assert(values.length == units.length);
    var total = 0;
    for (var i = 0; i < values.length; i++) {
      total = total * units[i].base + values[i];
      // برای آخرین واحد base معمولاً ۱ است
    }
    // اصلاح: units[i].base یعنی «چند واحد کوچک‌تر در این واحد»
    // محاسبه صحیح از بزرگ به کوچک:
    return _toSmallestCorrect(values);
  }

  int _toSmallestCorrect(List<int> values) {
    // units: [ساعت base=60, دقیقه base=60, ثانیه base=1]
    // total_seconds = h*3600 + m*60 + s
    var total = 0;
    var factor = 1;
    // اول ضریب‌ها را از کوچک به بزرگ بساز
    final factors = List<int>.filled(units.length, 1);
    for (var i = units.length - 2; i >= 0; i--) {
      factors[i] = factors[i + 1] * units[i].base;
    }
    // units[i].base = تعداد واحد i+1 در یک واحد i
    for (var i = 0; i < units.length; i++) {
      total += values[i] * factors[i];
    }
    return total;
  }

  List<int> fromSmallest(int total) {
    final result = List<int>.filled(units.length, 0);
    final factors = List<int>.filled(units.length, 1);
    for (var i = units.length - 2; i >= 0; i--) {
      factors[i] = factors[i + 1] * units[i].base;
    }
    var remaining = total;
    if (remaining < 0) remaining = -remaining;
    for (var i = 0; i < units.length; i++) {
      result[i] = remaining ~/ factors[i];
      remaining %= factors[i];
    }
    return result;
  }

  bool isNegative(int total) => total < 0;

  /// جمع
  CompoundResult add(List<int> a, List<int> b) {
    final sum = toSmallest(a) + toSmallest(b);
    return CompoundResult(
      values: fromSmallest(sum),
      negative: sum < 0,
      totalSmallest: sum,
    );
  }

  /// تفریق a - b
  CompoundResult subtract(List<int> a, List<int> b) {
    final diff = toSmallest(a) - toSmallest(b);
    return CompoundResult(
      values: fromSmallest(diff),
      negative: diff < 0,
      totalSmallest: diff,
    );
  }

  String format(List<int> values, {bool negative = false}) {
    final parts = <String>[];
    for (var i = 0; i < units.length; i++) {
      if (values[i] != 0 || i == units.length - 1) {
        parts.add('${values[i]} ${units[i].name}');
      }
    }
    final s = parts.join(' و ');
    return negative ? '− $s' : s;
  }
}

class CompoundResult {
  final List<int> values;
  final bool negative;
  final int totalSmallest;
  const CompoundResult({
    required this.values,
    required this.negative,
    required this.totalSmallest,
  });
}

class CompoundSystems {
  static final all = <CompoundSystem>[
    CompoundSystem(
      id: 'time',
      title: 'زمان',
      emoji: '⏱️',
      units: const [
        CompoundUnitDef('ساعت', 60),
        CompoundUnitDef('دقیقه', 60),
        CompoundUnitDef('ثانیه', 1),
      ],
    ),
    CompoundSystem(
      id: 'length',
      title: 'طول',
      emoji: '📏',
      units: const [
        CompoundUnitDef('متر', 100),
        CompoundUnitDef('سانتی‌متر', 10),
        CompoundUnitDef('میلی‌متر', 1),
      ],
    ),
    CompoundSystem(
      id: 'length_km',
      title: 'طول (کیلومتر)',
      emoji: '🛣️',
      units: const [
        CompoundUnitDef('کیلومتر', 1000),
        CompoundUnitDef('متر', 100),
        CompoundUnitDef('سانتی‌متر', 1),
      ],
    ),
    CompoundSystem(
      id: 'weight',
      title: 'وزن',
      emoji: '⚖️',
      units: const [
        CompoundUnitDef('کیلوگرم', 1000),
        CompoundUnitDef('گرم', 1000),
        CompoundUnitDef('میلی‌گرم', 1),
      ],
    ),
    CompoundSystem(
      id: 'angle',
      title: 'زاویه',
      emoji: '📐',
      units: const [
        CompoundUnitDef('درجه', 60),
        CompoundUnitDef('دقیقه', 60),
        CompoundUnitDef('ثانیه', 1),
      ],
    ),
    CompoundSystem(
      id: 'day_time',
      title: 'روز و ساعت',
      emoji: '📅',
      units: const [
        CompoundUnitDef('روز', 24),
        CompoundUnitDef('ساعت', 60),
        CompoundUnitDef('دقیقه', 1),
      ],
    ),
  ];
}

// ---------- features/compound/presentation/compound_screen.dart ----------
class CompoundScreen extends StatefulWidget {
  const CompoundScreen({super.key});

  @override
  State<CompoundScreen> createState() => _CompoundScreenState();
}

class _CompoundScreenState extends State<CompoundScreen> {
  late CompoundSystem _system;
  bool _isAdd = true; // true=جمع false=تفریق

  late List<TextEditingController> _a;
  late List<TextEditingController> _b;
  CompoundResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _system = CompoundSystems.all.first;
    _initControllers();
  }

  void _initControllers() {
    _a = List.generate(
        _system.units.length, (_) => TextEditingController(text: '0'));
    _b = List.generate(
        _system.units.length, (_) => TextEditingController(text: '0'));
    _result = null;
    _error = null;
  }

  @override
  void dispose() {
    for (final c in [..._a, ..._b]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changeSystem(CompoundSystem s) {
    for (final c in [..._a, ..._b]) {
      c.dispose();
    }
    setState(() {
      _system = s;
      _initControllers();
    });
  }

  List<int> _read(List<TextEditingController> ctrls) {
    return ctrls.map((c) {
      final v = int.tryParse(c.text.trim()) ?? 0;
      return v < 0 ? 0 : v;
    }).toList();
  }

  void _calculate() {
    try {
      final a = _read(_a);
      final b = _read(_b);
      // نرمال‌سازی ساده: اگر دقیقه=90 → خطا نمی‌دهیم، الگوریتم خودش carry می‌کند در نتیجه
      final res = _isAdd ? _system.add(a, b) : _system.subtract(a, b);
      setState(() {
        _result = res;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _result = null;
        _error = 'خطا در محاسبه';
      });
    }
  }

  void _clear() {
    for (final c in [..._a, ..._b]) {
      c.text = '0';
    }
    setState(() {
      _result = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('جمع و تفریق مرکب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clear,
            tooltip: 'پاک کردن',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // توضیح
          Card(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'اعداد مرکب از چند واحد ساخته می‌شوند؛ مثل ۲ ساعت و ۳۰ دقیقه. اینجا مثل درس ریاضی مدرسه جمع و تفریق می‌کنی و نتیجه با واحدهای درست نشان داده می‌شود.',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // نوع واحد
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: CompoundSystems.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final s = CompoundSystems.all[i];
                final selected = s.id == _system.id;
                return ChoiceChip(
                  label: Text('${s.emoji} ${s.title}',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        color: selected ? scheme.onPrimary : null,
                      )),
                  selected: selected,
                  selectedColor: scheme.primary,
                  onSelected: (_) => _changeSystem(s),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // عدد اول
          _numberCard('عدد اول', _a, scheme),
          const SizedBox(height: 12),

          // عملگر
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('＋  جمع',
                    style: TextStyle(fontFamily: 'Vazirmatn')),
                selected: _isAdd,
                selectedColor: scheme.primary,
                labelStyle: TextStyle(
                  color: _isAdd ? scheme.onPrimary : null,
                  fontFamily: 'Vazirmatn',
                ),
                onSelected: (_) => setState(() => _isAdd = true),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('−  تفریق',
                    style: TextStyle(fontFamily: 'Vazirmatn')),
                selected: !_isAdd,
                selectedColor: scheme.secondary,
                labelStyle: TextStyle(
                  color: !_isAdd ? scheme.onSecondary : null,
                  fontFamily: 'Vazirmatn',
                ),
                onSelected: (_) => setState(() => _isAdd = false),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // عدد دوم
          _numberCard('عدد دوم', _b, scheme),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('محاسبه',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16)),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Vazirmatn', color: Colors.red)),
          ],

          if (_result != null) ...[
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _isAdd ? 'حاصل جمع' : 'حاصل تفریق',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: scheme.primary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _system.format(_result!.values,
                          negative: _result!.negative),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // نمایش ستونی واحدها
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var i = 0; i < _system.units.length; i++)
                          Chip(
                            label: Text(
                              '${_result!.negative && _result!.values[i] > 0 ? '−' : ''}${_result!.values[i]} ${_system.units[i].name}',
                              style: const TextStyle(fontFamily: 'Vazirmatn'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // مثال راهنما
            Text(
              _exampleHint(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _exampleHint() {
    switch (_system.id) {
      case 'time':
        return 'مثال: ۲ ساعت ۴۵ دقیقه + ۱ ساعت ۲۰ دقیقه = ۴ ساعت و ۵ دقیقه';
      case 'length':
        return 'مثال: ۳ متر ۴۰ سانتی‌متر + ۲ متر ۷۰ سانتی‌متر = ۶ متر و ۱۰ سانتی‌متر';
      case 'angle':
        return 'مثال: ۴۵ درجه ۳۰ دقیقه + ۲۰ درجه ۴۰ دقیقه';
      default:
        return 'مقادیر را وارد کن و محاسبه را بزن';
    }
  }

  Widget _numberCard(
      String title, List<TextEditingController> ctrls, ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < _system.units.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: ctrls[i],
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: _system.units[i].name,
                        labelStyle: const TextStyle(
                            fontFamily: 'Vazirmatn', fontSize: 11),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- features/finance/logic/finance_logic.dart ----------
class FinanceLogic {
  /// محاسبه قسط ماهانه وام (فرمول amortization)
  /// [principal] مبلغ وام
  /// [annualRatePercent] نرخ سود سالانه به درصد
  /// [months] تعداد اقساط
  static double loanInstallment({
    required double principal,
    required double annualRatePercent,
    required int months,
  }) {
    if (principal <= 0 || months <= 0) return 0;
    if (annualRatePercent <= 0) return principal / months;

    final r = annualRatePercent / 100 / 12;
    final factor = math.pow(1 + r, months);
    return principal * r * factor / (factor - 1);
  }

  /// مجموع پرداختی و سود وام
  static Map<String, double> loanSummary({
    required double principal,
    required double annualRatePercent,
    required int months,
  }) {
    final installment = loanInstallment(
      principal: principal,
      annualRatePercent: annualRatePercent,
      months: months,
    );
    final total = installment * months;
    final interest = total - principal;
    return {
      'installment': installment,
      'total': total,
      'interest': interest,
    };
  }

  /// سود مرکب سپرده
  /// [principal] مبلغ اولیه
  /// [annualRatePercent] نرخ سالانه
  /// [years] مدت به سال
  /// [compoundsPerYear] تعداد مرکب در سال (۱۲ = ماهانه)
  static double compoundInterest({
    required double principal,
    required double annualRatePercent,
    required double years,
    int compoundsPerYear = 12,
  }) {
    if (principal <= 0 || years <= 0) return principal;
    final r = annualRatePercent / 100;
    return principal *
        math.pow(1 + r / compoundsPerYear, compoundsPerYear * years);
  }

  /// مالیات بر ارزش افزوده
  /// [amount] مبلغ قبل از مالیات
  /// [vatPercent] درصد مالیات (پیش‌فرض ۹)
  static Map<String, double> vat({
    required double amount,
    double vatPercent = 9,
  }) {
    final tax = amount * vatPercent / 100;
    return {
      'tax': tax,
      'total': amount + tax,
      'net': amount,
    };
  }

  /// مبلغ بدون مالیات از مبلغ نهایی
  static Map<String, double> reverseVat({
    required double totalWithVat,
    double vatPercent = 9,
  }) {
    final net = totalWithVat / (1 + vatPercent / 100);
    final tax = totalWithVat - net;
    return {
      'tax': tax,
      'total': totalWithVat,
      'net': net,
    };
  }

  /// درصد تغییر
  static double percentChange({
    required double from,
    required double to,
  }) {
    if (from == 0) return 0;
    return ((to - from) / from) * 100;
  }

  /// چند درصد از عدد
  static double percentOf({
    required double value,
    required double percent,
  }) {
    return value * percent / 100;
  }

  /// سود سپرده ساده (روزانه / ۳۰ روز / ۳۱ روز / سالانه)
  static Map<String, double> depositSimple({
    required double principal,
    required double annualRatePercent,
  }) {
    if (principal <= 0 || annualRatePercent < 0) {
      return {'daily': 0, 'd30': 0, 'd31': 0, 'yearly': 0};
    }
    final yearly = principal * annualRatePercent / 100;
    final daily = yearly / 365;
    return {
      'daily': daily,
      'd30': daily * 30,
      'd31': daily * 31,
      'yearly': yearly,
    };
  }

  /// محاسبه قیمت طلا (ایران — مالیات فقط روی اجرت و سود)
  static Map<String, double> goldPrice({
    required double pricePerGram,
    required double weightGram,
    required double wagePercent,
    required double profitPercent,
    required double taxPercent,
  }) {
    final raw = pricePerGram * weightGram;
    final wage = raw * wagePercent / 100;
    final profit = raw * profitPercent / 100;
    final tax = (wage + profit) * taxPercent / 100;
    final total = raw + wage + profit + tax;
    return {
      'raw': raw,
      'wage': wage,
      'profit': profit,
      'tax': tax,
      'total': total,
    };
  }
}

// ---------- features/finance/presentation/finance_screen.dart ----------


/// فرمت‌دهنده ورودی عددی با جداکننده هزارگان
class GroupedNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = NumFmt.groupTyping(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}


class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محاسبه سود سپرده، وام، طلا'),
        bottom: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
          tabs: const [
            Tab(text: 'سود سپرده'),
            Tab(text: 'سود وام'),
            Tab(text: 'محاسبه طلا'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _DepositTab(),
          _LoanTab(),
          _GoldTab(),
        ],
      ),
    );
  }
}

// ---------- سود سپرده (ساده روزانه) ----------
class _DepositTab extends StatefulWidget {
  const _DepositTab();

  @override
  State<_DepositTab> createState() => _DepositTabState();
}

class _DepositTabState extends State<_DepositTab> {
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  Map<String, double> _r = const {
    'daily': 0,
    'd30': 0,
    'd31': 0,
    'yearly': 0,
  };

  void _recalc() {
    setState(() {
      _r = FinanceLogic.depositSimple(
        principal: NumFmt.parse(_principal.text),
        annualRatePercent: NumFmt.parse(_rate.text),
      );
    });
  }

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field(_principal, 'مبلغ سرمایه‌گذاری', Icons.savings_outlined,
            onChanged: _recalc),
        const SizedBox(height: 12),
        _field(_rate, 'نرخ سود (درصد)', Icons.percent, onChanged: _recalc),
        const SizedBox(height: 16),
        _readonlyRow('سود سپرده در روز', _r['daily']!),
        const SizedBox(height: 8),
        _readonlyRow('سود سپرده در ماه ۳۰ روزه', _r['d30']!),
        const SizedBox(height: 8),
        _readonlyRow('سود سپرده در ماه ۳۱ روز', _r['d31']!),
        const SizedBox(height: 8),
        _readonlyRow('سود سپرده در سال', _r['yearly']!),
      ],
    );
  }
}

// ---------- سود وام ----------
class _LoanTab extends StatefulWidget {
  const _LoanTab();

  @override
  State<_LoanTab> createState() => _LoanTabState();
}

class _LoanTabState extends State<_LoanTab> {
  final _principal = TextEditingController();
  final _rate = TextEditingController(text: '18');
  final _months = TextEditingController(text: '12');
  Map<String, double>? _result;

  void _calc() {
    setState(() {
      _result = FinanceLogic.loanSummary(
        principal: NumFmt.parse(_principal.text),
        annualRatePercent: NumFmt.parse(_rate.text),
        months: NumFmt.parse(_months.text).round(),
      );
    });
  }

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _months.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field(_principal, 'مبلغ وام (تومان)', Icons.payments_outlined),
        const SizedBox(height: 12),
        _field(_rate, 'نرخ سود سالانه (%)', Icons.percent),
        const SizedBox(height: 12),
        _field(_months, 'تعداد اقساط (ماه)', Icons.calendar_today_outlined,
            integer: true),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _calc,
          icon: const Icon(Icons.calculate),
          label: const Text('محاسبه', style: TextStyle(fontFamily: 'Vazirmatn')),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        if (_result != null) ...[
          const SizedBox(height: 20),
          _resultCard('قسط ماهانه', _fmtMoney(_result!['installment']!)),
          _resultCard('مجموع پرداختی', _fmtMoney(_result!['total']!)),
          _resultCard('کل سود', _fmtMoney(_result!['interest']!),
              color: Colors.orange),
        ],
      ],
    );
  }
}

// ---------- محاسبه طلا ----------
class _GoldTab extends StatefulWidget {
  const _GoldTab();

  @override
  State<_GoldTab> createState() => _GoldTabState();
}

class _GoldTabState extends State<_GoldTab> {
  final _price = TextEditingController();
  final _weight = TextEditingController();
  final _wage = TextEditingController(text: '10');
  final _profit = TextEditingController(text: '7');
  final _tax = TextEditingController(text: '9');
  Map<String, double> _r = const {
    'raw': 0,
    'wage': 0,
    'profit': 0,
    'tax': 0,
    'total': 0,
  };
  bool _loadingPrice = false;
  String? _priceMsg;

  void _recalc() {
    setState(() {
      _r = FinanceLogic.goldPrice(
        pricePerGram: NumFmt.parse(_price.text),
        weightGram: NumFmt.parse(_weight.text),
        wagePercent: NumFmt.parse(_wage.text),
        profitPercent: NumFmt.parse(_profit.text),
        taxPercent: NumFmt.parse(_tax.text),
      );
    });
  }

  Future<void> _fetchGoldPrice() async {
    setState(() {
      _loadingPrice = true;
      _priceMsg = null;
    });
    double? price;
    String? source;

    Future<double?> tryUrl(String url, double? Function(dynamic json) parse) async {
      try {
        final res = await http
            .get(Uri.parse(url), headers: {'Accept': 'application/json', 'User-Agent': 'HesabgarMan/1.0'})
            .timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) return null;
        final body = jsonDecode(res.body);
        return parse(body);
      } catch (_) {
        return null;
      }
    }

    // ۱) iran-market رایگان — طلای ۱۸ عیار (تومان)
    price = await tryUrl(
      'https://cdn.jsdelivr.net/gh/iran-market/iran-market.github.io@main/data/popular.json',
      (body) {
        if (body is! Map) return null;
        final list = body['data'];
        if (list is! List) return null;
        for (final item in list) {
          if (item is Map && item['symbol'] == 'GOLD_18K_IRR') {
            final v = item['price'];
            if (v is num && v > 100000) return v.toDouble();
          }
        }
        return null;
      },
    );
    if (price != null) source = 'iran-market';

    // ۲) raw github همان منبع
    if (price == null) {
      price = await tryUrl(
        'https://raw.githubusercontent.com/iran-market/iran-market.github.io/main/data/popular.json',
        (body) {
          if (body is! Map) return null;
          final list = body['data'];
          if (list is! List) return null;
          for (final item in list) {
            if (item is Map && item['symbol'] == 'GOLD_18K_IRR') {
              final v = item['price'];
              if (v is num && v > 100000) return v.toDouble();
            }
          }
          return null;
        },
      );
      if (price != null) source = 'iran-market';
    }

    // ۳) tgju ajax
    if (price == null) {
      price = await tryUrl(
        'https://call1.tgju.org/ajax.json',
        (body) {
          if (body is! Map) return null;
          for (final key in ['geram18', 'gold_geram18']) {
            final item = body[key];
            if (item is Map && item['p'] != null) {
              final raw = item['p'].toString().replaceAll(',', '').replaceAll('٬', '');
              final v = double.tryParse(raw);
              if (v != null && v > 100000) return v;
            }
          }
          double? found;
          body.forEach((k, v) {
            if (found != null) return;
            if (k.toString().toLowerCase().contains('geram18') && v is Map) {
              final raw = v['p']?.toString().replaceAll(',', '').replaceAll('٬', '') ?? '';
              final val = double.tryParse(raw);
              if (val != null && val > 100000) found = val;
            }
          });
          return found;
        },
      );
      if (price != null) source = 'tgju';
    }

    final fetched = price;
    if (fetched != null && fetched > 0) {
      _price.text = NumFmt.format(fetched);
      _priceMsg = 'نرخ طلای ۱۸ عیار به‌روز شد${source != null ? ' ($source)' : ''}';
      _recalc();
    } else {
      _priceMsg =
          'دریافت خودکار ممکن نشد؛ قیمت هر گرم را دستی وارد کنید';
    }
    if (mounted) {
      setState(() => _loadingPrice = false);
    }
  }

  @override
  void dispose() {
    _price.dispose();
    _weight.dispose();
    _wage.dispose();
    _profit.dispose();
    _tax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            GroupedNumberFormatter(),
          ],
          onChanged: (_) => _recalc(),
          style: const TextStyle(fontFamily: 'Vazirmatn'),
          decoration: InputDecoration(
            labelText: 'قیمت هر گرم طلا (تومان)',
            labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: _loadingPrice
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'دریافت نرخ آنلاین',
                    onPressed: _fetchGoldPrice,
                  ),
          ),
        ),
        if (_priceMsg != null) ...[
          const SizedBox(height: 6),
          Text(_priceMsg!,
              style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: scheme.primary)),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(_weight, 'وزن طلا (گرم)', Icons.scale,
                  onChanged: _recalc),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _field(_wage, 'اجرت ساخت (٪)', Icons.build_outlined,
                  onChanged: _recalc),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(_profit, 'درصد سود فروشنده', Icons.trending_up,
                  onChanged: _recalc),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _field(_tax, 'درصد مالیات', Icons.receipt_long,
                  onChanged: _recalc),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _readonlyRow('قیمت نهایی', _r['total']!),
        const SizedBox(height: 8),
        _resultCard('ارزش طلا', _fmtMoney(_r['raw']!)),
        _resultCard('اجرت ساخت', _fmtMoney(_r['wage']!)),
        _resultCard('سود فروشنده', _fmtMoney(_r['profit']!)),
        _resultCard('مالیات', _fmtMoney(_r['tax']!), color: Colors.orange),
        const SizedBox(height: 12),
        Text(
          'از دی‌ماه ۱۴۰۰ مالیات بر ارزش افزوده طلا تنها روی اجرت ساخت و سود فروشنده لحاظ می‌شود.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

Widget _readonlyRow(String title, double value) {
  return InputDecorator(
    decoration: InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14)),
        ),
        Text(
          NumFmt.format(value),
          style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

Widget _field(TextEditingController c, String label, IconData icon,
    {bool integer = false, VoidCallback? onChanged}) {
  return TextField(
    controller: c,
    keyboardType: TextInputType.numberWithOptions(decimal: !integer),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      GroupedNumberFormatter(),
    ],
    onChanged: (_) {
      final g = NumFmt.groupTyping(c.text);
      if (g != c.text) {
        c.value = TextEditingValue(
          text: g,
          selection: TextSelection.collapsed(offset: g.length),
        );
      }
      onChanged?.call();
    },
    style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 16),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
    ),
  );
}

Widget _resultCard(String title, String value, {Color? color}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      title: Text(title,
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14)),
      trailing: Text(
        value,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color ?? AppColors.primary,
        ),
      ),
    ),
  );
}

String _fmtMoney(double v) {
  if (v.isNaN || v.isInfinite) return '—';
  return '${NumFmt.format(v)} تومان';
}

// ---------- features/expenses/logic/expense_model.dart ----------
class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final bool isIncome;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.isIncome = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
        'isIncome': isIncome,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String? ?? 'سایر',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        note: json['note'] as String?,
        isIncome: json['isIncome'] as bool? ?? false,
      );

  static const expenseCategories = [
    'خوراک',
    'حمل‌ونقل',
    'مسکن',
    'قبوض',
    'سلامت',
    'آموزش',
    'تفریح',
    'پوشاک',
    'خرید',
    'سایر',
  ];

  static const incomeCategories = [
    'حقوق',
    'فروش',
    'هدیه',
    'سود',
    'سایر درآمد',
  ];
}

class ExpenseStore {
  static const _key = 'expenses_v2';
  List<Expense> _items = [];

  List<Expense> get items => List.unmodifiable(_items);

  List<Expense> get expenses =>
      _items.where((e) => !e.isIncome).toList();
  List<Expense> get incomes =>
      _items.where((e) => e.isIncome).toList();

  double get totalExpense =>
      expenses.fold(0.0, (s, e) => s + e.amount);
  double get totalIncome =>
      incomes.fold(0.0, (s, e) => s + e.amount);
  double get balance => totalIncome - totalExpense;

  List<Expense> forMonth(int year, int month) => _items
      .where((e) => e.date.year == year && e.date.month == month)
      .toList();

  double expenseInMonth(int year, int month) => forMonth(year, month)
      .where((e) => !e.isIncome)
      .fold(0.0, (s, e) => s + e.amount);

  double incomeInMonth(int year, int month) => forMonth(year, month)
      .where((e) => e.isIncome)
      .fold(0.0, (s, e) => s + e.amount);

  Map<String, double> categoryTotals(
      {bool income = false, int? year, int? month}) {
    final map = <String, double>{};
    for (final e in _items) {
      if (e.isIncome != income) continue;
      if (year != null && e.date.year != year) continue;
      if (month != null && e.date.month != month) continue;
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  Future<void> load() async {
    try {
      final store = await LocalStore.instance;
      final raw = store.getString(_key);
      if (raw == null || raw.isEmpty) {
        _items = [];
        return;
      }
      final list = jsonDecode(raw) as List;
      _items = list
          .map((e) {
            try {
              return Expense.fromJson(e as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<Expense>()
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('ExpenseStore load: $e');
      _items = [];
    }
  }

  Future<void> add(Expense expense) async {
    _items.insert(0, expense);
    await _save();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _save();
  }

  Future<void> clear() async {
    _items = [];
    await _save();
  }

  Future<void> _save() async {
    try {
      final store = await LocalStore.instance;
      final raw = jsonEncode(_items.map((e) => e.toJson()).toList());
      await store.setString(_key, raw);
    } catch (e) {
      debugPrint('ExpenseStore save: $e');
    }
  }
}

// ---------- features/expenses/presentation/expenses_screen.dart ----------
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  final _store = ExpenseStore();
  bool _loading = true;
  String? _error;
  late TabController _tab;
  late int _filterMonth;
  late int _filterYear;

  @override
  void initState() {
    super.initState();
    final j = Jalali.fromDateTime(DateTime.now());
    _filterYear = j.year;
    _filterMonth = j.month;
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _store.load().timeout(const Duration(seconds: 5));
    } catch (e) {
      _error = 'خطا در بارگذاری';
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmt(double v) {
    final neg = v < 0;
    final s = v.abs().toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${neg ? '-' : ''}${buf.toString()}';
  }

  Future<void> _openEditor({Expense? existing, bool income = false}) async {
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddSheet(initial: existing, asIncome: income),
    );
    if (result != null) {
      if (existing != null) await _store.remove(existing.id);
      await _store.add(result);
      setState(() {});
    }
  }

  Future<void> _delete(Expense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف', style: TextStyle(fontFamily: 'Vazirmatn')),
        content: Text('«${e.title}» حذف شود؟',
            style: const TextStyle(fontFamily: 'Vazirmatn')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف',
                  style: TextStyle(fontFamily: 'Vazirmatn'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف',
                  style:
                      TextStyle(fontFamily: 'Vazirmatn', color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _store.remove(e.id);
      setState(() {});
    }
  }

  List<Expense> get _monthItems {
    return _store.items.where((e) {
      final j = Jalali.fromDateTime(e.date);
      return j.year == _filterYear && j.month == _filterMonth;
    }).toList();
  }

  double get _monthExp =>
      _monthItems.where((e) => !e.isIncome).fold(0.0, (s, e) => s + e.amount);
  double get _monthInc =>
      _monthItems.where((e) => e.isIncome).fold(0.0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final monthExp = _monthExp;
    final monthInc = _monthInc;
    final monthBal = monthInc - monthExp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('هزینه‌ها و درآمد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'بازنشانی',
          ),
          if (_store.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('پاک کردن همه',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    content: const Text('همه تراکنش‌ها حذف شوند؟',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('انصراف',
                              style: TextStyle(fontFamily: 'Vazirmatn'))),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('حذف',
                              style: TextStyle(
                                  fontFamily: 'Vazirmatn', color: Colors.red))),
                    ],
                  ),
                );
                if (ok == true) {
                  await _store.clear();
                  setState(() {});
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
          tabs: const [
            Tab(text: 'خلاصه'),
            Tab(text: 'تراکنش‌ها'),
            Tab(text: 'دسته‌ها'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final choice = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.arrow_upward, color: Colors.red),
                    title: const Text('ثبت هزینه',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    onTap: () => Navigator.pop(ctx, 'expense'),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.arrow_downward, color: Colors.green),
                    title: const Text('ثبت درآمد',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    onTap: () => Navigator.pop(ctx, 'income'),
                  ),
                ],
              ),
            ),
          );
          if (choice == 'expense') await _openEditor(income: false);
          if (choice == 'income') await _openEditor(income: true);
        },
        icon: const Icon(Icons.add),
        label: const Text('جدید', style: TextStyle(fontFamily: 'Vazirmatn')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(fontFamily: 'Vazirmatn')),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _load,
                          child: const Text('تلاش دوباره',
                              style: TextStyle(fontFamily: 'Vazirmatn'))),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // فیلتر ماه
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _filterMonth--;
                                if (_filterMonth < 1) {
                                  _filterMonth = 12;
                                  _filterYear--;
                                }
                              });
                            },
                            icon: const Icon(Icons.chevron_right),
                          ),
                          Expanded(
                            child: Text(
                              '$_filterYear / ${Jalali.monthNames[_filterMonth - 1]}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _filterMonth++;
                                if (_filterMonth > 12) {
                                  _filterMonth = 1;
                                  _filterYear++;
                                }
                              });
                            },
                            icon: const Icon(Icons.chevron_left),
                          ),
                        ],
                      ),
                    ),
                    // کارت خلاصه ماه
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _miniStat('درآمد', _fmt(monthInc),
                                Colors.green, Icons.south_west),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _miniStat('هزینه', _fmt(monthExp),
                                Colors.redAccent, Icons.north_east),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _miniStat(
                              'مانده',
                              _fmt(monthBal),
                              monthBal >= 0 ? scheme.primary : Colors.orange,
                              Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          _buildSummary(scheme, monthExp, monthInc),
                          _buildList(),
                          _buildCategories(scheme),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _miniStat(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(value,
                  style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ColorScheme scheme, double exp, double inc) {
    final items = _monthItems;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: scheme.primary.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            const Text('این ماه تراکنشی نیست',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16)),
            const SizedBox(height: 8),
            const Text('با دکمه «جدید» ثبت کنید',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
          ],
        ),
      );
    }

    final catMap = <String, double>{};
    for (final e in _monthItems.where((e) => !e.isIncome)) {
      catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
    }
    final total = catMap.values.fold(0.0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('توزیع هزینه‌ها',
                    style: TextStyle(
                        fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (catMap.isEmpty)
                  const Text('هزینه‌ای ثبت نشده',
                      style: TextStyle(fontFamily: 'Vazirmatn'))
                else
                  ...catMap.entries.map((e) {
                    final pct = total > 0 ? e.value / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(e.key,
                                  style: const TextStyle(
                                      fontFamily: 'Vazirmatn', fontSize: 13)),
                              const Spacer(),
                              Text(
                                '${_fmt(e.value)} (${(pct * 100).toStringAsFixed(0)}٪)',
                                style: const TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor:
                                  scheme.surfaceContainerHighest,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('تعداد تراکنش این ماه',
                style: TextStyle(fontFamily: 'Vazirmatn')),
            trailing: Text('${items.length}',
                style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    final items = _monthItems;
    if (items.isEmpty) {
      return const Center(
          child: Text('تراکنشی در این ماه نیست',
              style: TextStyle(fontFamily: 'Vazirmatn')));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final e = items[i];
        final color = e.isIncome ? Colors.green : Colors.redAccent;
        return Dismissible(
          key: Key(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) async {
            await _store.remove(e.id);
            setState(() {});
          },
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  e.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                  size: 20,
                ),
              ),
              title: Text(e.title,
                  style: const TextStyle(
                      fontFamily: 'Vazirmatn', fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${e.category} • ${Jalali.fromDateTime(e.date)}',
                style:
                    const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
              ),
              trailing: Text(
                '${e.isIncome ? '+' : '-'}${_fmt(e.amount)}',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              onTap: () => _openEditor(existing: e, income: e.isIncome),
              onLongPress: () => _delete(e),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategories(ColorScheme scheme) {
    final expMap = <String, double>{};
    final incMap = <String, double>{};
    for (final e in _monthItems) {
      if (e.isIncome) {
        incMap[e.category] = (incMap[e.category] ?? 0) + e.amount;
      } else {
        expMap[e.category] = (expMap[e.category] ?? 0) + e.amount;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        const Text('هزینه‌ها بر اساس دسته',
            style: TextStyle(
                fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (expMap.isEmpty)
          const Text('—', style: TextStyle(fontFamily: 'Vazirmatn'))
        else
          ...expMap.entries.map((e) => Card(
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: Text(e.key,
                      style: const TextStyle(fontFamily: 'Vazirmatn')),
                  trailing: Text(_fmt(e.value),
                      style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)),
                ),
              )),
        const SizedBox(height: 16),
        const Text('درآمدها بر اساس دسته',
            style: TextStyle(
                fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (incMap.isEmpty)
          const Text('—', style: TextStyle(fontFamily: 'Vazirmatn'))
        else
          ...incMap.entries.map((e) => Card(
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(e.key,
                      style: const TextStyle(fontFamily: 'Vazirmatn')),
                  trailing: Text(_fmt(e.value),
                      style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ),
              )),
      ],
    );
  }
}

class _AddSheet extends StatefulWidget {
  final Expense? initial;
  final bool asIncome;
  const _AddSheet({this.initial, this.asIncome = false});

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String _category;
  late bool _isIncome;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _isIncome = i?.isIncome ?? widget.asIncome;
    _title = TextEditingController(text: i?.title ?? '');
    _amount = TextEditingController(
        text: i != null ? i.amount.toStringAsFixed(0) : '');
    _note = TextEditingController(text: i?.note ?? '');
    _category = i?.category ??
        (_isIncome
            ? Expense.incomeCategories.first
            : Expense.expenseCategories.first);
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    final amount = NumFmt.parse(_amount.text);
    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('عنوان و مبلغ را درست وارد کنید',
              style: TextStyle(fontFamily: 'Vazirmatn'))));
      return;
    }
    Navigator.pop(
      context,
      Expense(
        id: widget.initial?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        amount: amount,
        category: _category,
        date: widget.initial?.date ?? DateTime.now(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        isIncome: _isIncome,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats =
        _isIncome ? Expense.incomeCategories : Expense.expenseCategories;
    if (!cats.contains(_category)) _category = cats.first;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isIncome ? 'ثبت درآمد' : 'ثبت هزینه',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    label: Text('هزینه',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    icon: Icon(Icons.arrow_upward)),
                ButtonSegment(
                    value: true,
                    label: Text('درآمد',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_isIncome},
              onSelectionChanged: (s) => setState(() {
                _isIncome = s.first;
                _category = _isIncome
                    ? Expense.incomeCategories.first
                    : Expense.expenseCategories.first;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              style: const TextStyle(fontFamily: 'Vazirmatn'),
              decoration: InputDecoration(
                labelText: 'عنوان',
                labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                GroupedNumberFormatter(),
              ],
              onChanged: (v) {
                final g = NumFmt.groupTyping(v);
                if (g != v) {
                  _amount.value = TextEditingValue(
                    text: g,
                    selection: TextSelection.collapsed(offset: g.length),
                  );
                }
              },
              style: const TextStyle(fontFamily: 'Vazirmatn'),
              decoration: InputDecoration(
                labelText: 'مبلغ (تومان)',
                labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'دسته‌بندی',
                labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: cats
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: const TextStyle(fontFamily: 'Vazirmatn'))))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              style: const TextStyle(fontFamily: 'Vazirmatn'),
              decoration: InputDecoration(
                labelText: 'یادداشت (اختیاری)',
                labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('ذخیره',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- features/calendar/logic/jalali.dart ----------
/// تبدیل ساده میلادی ↔ شمسی (الگوریتم استاندارد)
class Jalali {
  final int year;
  final int month;
  final int day;

  const Jalali(this.year, this.month, this.day);

  static const monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const weekDays = [
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
  ];

  String get monthName => monthNames[month - 1];

  /// تعداد روزهای ماه شمسی
  int get monthLength {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return isLeap(year) ? 30 : 29;
  }

  static bool isLeap(int year) {
    final breaks = [
      -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181,
      1210, 1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178
    ];
    final jp = breaks.indexWhere((b) => year < b);
    final jump = breaks[jp] - breaks[jp - 1];
    var n = year - breaks[jp - 1];
    if (jump - n < 6) n = n - jump + ((jump + 4) ~/ 33) * 33;
    var leap = ((n + 1) % 33) % 4;
    if (jump == 33 && leap == 1) leap = 0;
    return leap == 1;
  }

  static Jalali fromDateTime(DateTime dt) {
    // فقط سال/ماه/روز محلی — بدون اثر timezone
    final local = DateTime(dt.year, dt.month, dt.day);
    return fromGregorian(local.year, local.month, local.day);
  }

  static Jalali fromGregorian(int gy, int gm, int gd) {
    final gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    var gy2 = (gm > 2) ? (gy + 1) : gy;
    var days = 355666 +
        (365 * gy) +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) +
        gd +
        gdm[gm - 1];
    var jy = -1595 + (33 * (days ~/ 12053));
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    int jm, jd;
    if (days < 186) {
      jm = 1 + (days ~/ 31);
      jd = 1 + (days % 31);
    } else {
      jm = 7 + ((days - 186) ~/ 30);
      jd = 1 + ((days - 186) % 30);
    }
    return Jalali(jy, jm, jd);
  }

  DateTime toDateTime() {
    final jdn = _jalaliToJdn(year, month, day);
    final g = _jdnToGregorian(jdn);
    // ظهر محلی تا مشکل timezone باعث جابه‌جایی روز نشود
    return DateTime(g.year, g.month, g.day, 12);
  }

  static int _jalaliToJdn(int jy, int jm, int jd) {
    final epbase = jy - ((jy >= 0) ? 474 : 473);
    final epyear = 474 + (epbase % 2820);
    return jd +
        ((jm <= 7) ? ((jm - 1) * 31) : (((jm - 1) * 30) + 6)) +
        (((epyear * 682) - 110) ~/ 2816) +
        (epyear - 1) * 365 +
        (epbase ~/ 2820) * 1029983 +
        1948320;
  }

  static DateTime _jdnToGregorian(int jdn) {
    var j = 4 * jdn + 139361631;
    j = j + ((((4 * jdn + 183187720) ~/ 146097) * 3) ~/ 4) * 4 - 3908;
    final i = ((j % 1461) ~/ 4) * 5 + 308;
    final gd = ((i % 153) ~/ 5) + 1;
    final gm = ((i ~/ 153) % 12) + 1;
    final gy = (j ~/ 1461) - 100100 + ((8 - gm) ~/ 6);
    return DateTime(gy, gm, gd);
  }

  /// روز هفته: ۰ = شنبه
  int get weekDay {
    final dt = toDateTime();
    // DateTime.weekday: 1=Mon ... 7=Sun
    // شمسی: شنبه=0
    return (dt.weekday % 7); // Sun=0 in this formula... wait
    // Monday=1 -> we want Sat=0
    // Sat=6 in DateTime -> 0
    // Sun=7 -> 1
    // Mon=1 -> 2
  }

  int get weekdayIndex {
    final wd = toDateTime().weekday; // 1=Mon ... 7=Sun
    // Map to Sat=0, Sun=1, ..., Fri=6
    return (wd % 7 + 1) % 7; // Sun(7)->1, Mon(1)->2, ... Sat(6)->0
    // Actually: Sat=6 -> (6%7+1)%7 = 0 ✓
    // Sun=7 -> (0+1)%7 = 1 ✓
    // Mon=1 -> (1+1)%7 = 2 ✓
    // Fri=5 -> (5+1)%7 = 6 ✓
  }

  Jalali addMonths(int n) {
    var y = year;
    var m = month + n;
    while (m > 12) {
      m -= 12;
      y++;
    }
    while (m < 1) {
      m += 12;
      y--;
    }
    final maxDay = Jalali(y, m, 1).monthLength;
    final d = day > maxDay ? maxDay : day;
    return Jalali(y, m, d);
  }

  @override
  String toString() =>
      '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}';
}

// ---------- features/calendar/presentation/calendar_screen.dart ----------

// ---------- تقویم چندگانه + مناسبت‌ها ----------
class HijriDate {
  final int year, month, day;
  const HijriDate(this.year, this.month, this.day);

  static const monthNames = [
    'محرم', 'صفر', 'ربیع‌الاول', 'ربیع‌الثانی', 'جمادی‌الاول', 'جمادی‌الثانی',
    'رجب', 'شعبان', 'رمضان', 'شوال', 'ذیقعده', 'ذیحجه',
  ];

  /// تقریب استاندارد تبدیل میلادی → قمری
  static HijriDate fromGregorian(DateTime dt) {
    final jd = _gregorianToJd(dt.year, dt.month, dt.day);
    return _jdToHijri(jd);
  }

  static int _gregorianToJd(int y, int m, int d) {
    final a = ((14 - m) ~/ 12);
    final y2 = y + 4800 - a;
    final m2 = m + 12 * a - 3;
    return d + ((153 * m2 + 2) ~/ 5) + 365 * y2 + (y2 ~/ 4) - (y2 ~/ 100) + (y2 ~/ 400) - 32045;
  }

  static HijriDate _jdToHijri(int jd) {
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) ~/ 10631);
    final l2 = l - 10631 * n + 354;
    final j = ((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719) + (l2 ~/ 5670) * ((43 * l2) ~/ 15238);
    final l3 = l2 - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
    var m = (24 * l3) ~/ 709;
    var d = l3 - (709 * m) ~/ 24;
    var y = 30 * n + j - 30;
    if (d < 1) d = 1;
    if (m < 1) m = 1;
    if (m > 12) m = 12;
    return HijriDate(y, m, d);
  }

  @override
  String toString() => '$day ${monthNames[month - 1]} $year';
}

class CalendarOccasion {
  final int month; // در سیستم همان تقویم
  final int day;
  final String title;
  final bool isHoliday;
  const CalendarOccasion(this.month, this.day, this.title, {this.isHoliday = false});
}

class OccasionData {
  /// مناسبت‌های ثابت شمسی (ملی/مذهبی رایج)
  static const jalali = <CalendarOccasion>[
    CalendarOccasion(1, 1, 'عید نوروز', isHoliday: true),
    CalendarOccasion(1, 2, 'عید نوروز', isHoliday: true),
    CalendarOccasion(1, 3, 'عید نوروز', isHoliday: true),
    CalendarOccasion(1, 4, 'عید نوروز', isHoliday: true),
    CalendarOccasion(1, 12, 'روز جمهوری اسلامی', isHoliday: true),
    CalendarOccasion(1, 13, 'روز طبیعت (سیزده‌به‌در)', isHoliday: true),
    CalendarOccasion(3, 14, 'رحلت امام خمینی', isHoliday: true),
    CalendarOccasion(3, 15, 'قیام ۱۵ خرداد', isHoliday: true),
    CalendarOccasion(11, 22, 'پیروزی انقلاب اسلامی', isHoliday: true),
    CalendarOccasion(12, 29, 'ملی شدن صنعت نفت', isHoliday: true),
    CalendarOccasion(7, 13, 'روز نیروی دریایی'),
    CalendarOccasion(8, 4, 'روز ارتش'),
    CalendarOccasion(9, 16, 'روز دانشجو'),
    CalendarOccasion(10, 12, 'روز میلاد حضرت رسول (تقریبی ملی)'),
    CalendarOccasion(2, 25, 'روز بزرگداشت فردوسی'),
    CalendarOccasion(5, 15, 'روز مهر'),
  ];

  static const gregorian = <CalendarOccasion>[
    CalendarOccasion(1, 1, 'سال نو میلادی'),
    CalendarOccasion(2, 14, 'ولنتاین'),
    CalendarOccasion(3, 8, 'روز جهانی زن'),
    CalendarOccasion(4, 22, 'روز زمین'),
    CalendarOccasion(5, 1, 'روز جهانی کارگر'),
    CalendarOccasion(6, 5, 'روز محیط زیست'),
    CalendarOccasion(10, 31, 'هالووین'),
    CalendarOccasion(12, 25, 'کریسمس'),
    CalendarOccasion(12, 31, 'شب سال نو'),
  ];

  static const hijri = <CalendarOccasion>[
    CalendarOccasion(1, 10, 'عاشورای حسینی', isHoliday: true),
    CalendarOccasion(1, 9, 'تاسوعای حسینی', isHoliday: true),
    CalendarOccasion(2, 20, 'اربعین حسینی', isHoliday: true),
    CalendarOccasion(2, 28, 'رحلت پیامبر و شهادت امام حسن', isHoliday: true),
    CalendarOccasion(3, 17, 'میلاد پیامبر و امام صادق', isHoliday: true),
    CalendarOccasion(7, 13, 'ولادت امام علی', isHoliday: true),
    CalendarOccasion(7, 27, 'مبعث پیامبر', isHoliday: true),
    CalendarOccasion(8, 15, 'ولادت امام زمان', isHoliday: true),
    CalendarOccasion(9, 21, 'شهادت امام علی', isHoliday: true),
    CalendarOccasion(10, 1, 'عید فطر', isHoliday: true),
    CalendarOccasion(10, 2, 'تعطیلی عید فطر', isHoliday: true),
    CalendarOccasion(12, 10, 'عید قربان', isHoliday: true),
    CalendarOccasion(12, 18, 'عید غدیر', isHoliday: true),
  ];

  static List<CalendarOccasion> forDay({
    required String system,
    required int month,
    required int day,
  }) {
    final list = system == 'gregorian'
        ? gregorian
        : system == 'hijri'
            ? hijri
            : jalali;
    return list.where((o) => o.month == month && o.day == day).toList();
  }
}


class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Jalali _focused; // ماه نمایش (شمسی)
  late Jalali _todayJ;
  DateTime? _selectedG;

  static const _gMonths = [
    'ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن',
    'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر',
  ];

  @override
  void initState() {
    super.initState();
    _todayJ = Jalali.fromDateTime(DateTime.now());
    _focused = Jalali(_todayJ.year, _todayJ.month, 1);
    _selectedG = DateTime.now();
  }

  Jalali get _selectedJ =>
      Jalali.fromDateTime(_selectedG ?? DateTime.now());

  HijriDate get _selectedH =>
      HijriDate.fromGregorian(_selectedG ?? DateTime.now());

  void _prevMonth() => setState(() => _focused = _focused.addMonths(-1));
  void _nextMonth() => setState(() => _focused = _focused.addMonths(1));
  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _selectedG = now;
      final j = Jalali.fromDateTime(now);
      _focused = Jalali(j.year, j.month, 1);
    });
  }

  void _onDay(int day) {
    final j = Jalali(_focused.year, _focused.month, day);
    final g = j.toDateTime();
    setState(() => _selectedG = g);
  }

  void _showOccasions() {
    final j = _selectedJ;
    final g = _selectedG ?? DateTime.now();
    final h = _selectedH;
    final all = <String>[
      ...OccasionData.forDay(system: 'jalali', month: j.month, day: j.day)
          .map((o) => o.title),
      ...OccasionData.forDay(system: 'gregorian', month: g.month, day: g.day)
          .map((o) => o.title),
      ...OccasionData.forDay(system: 'hijri', month: h.month, day: h.day)
          .map((o) => o.title),
    ];
    final uniq = all.toSet().toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${Jalali.weekDays[j.weekdayIndex]} ${j.day} ${j.monthName} ${j.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'قمری: $h\nمیلادی: ${g.day} ${_gMonths[g.month - 1]} ${g.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Vazirmatn', fontSize: 13, height: 1.5),
            ),
            const Divider(height: 24),
            const Text('مناسبت‌ها',
                style: TextStyle(
                    fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (uniq.isEmpty)
              const Text('مناسبت ثبت‌شده‌ای نیست',
                  style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey))
            else
              ...uniq.map((e) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.event, size: 20),
                    title:
                        Text(e, style: const TextStyle(fontFamily: 'Vazirmatn')),
                  )),
          ],
        ),
      ),
    );
  }

  void _showConverter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const _DateConverterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daysInMonth = _focused.monthLength;
    final leading = Jalali(_focused.year, _focused.month, 1).weekdayIndex;
    final weekDays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    final sel = _selectedJ;
    final g = _selectedG ?? DateTime.now();
    final h = _selectedH;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('امروز', style: TextStyle(fontSize: 12)),
            Text(
              '${Jalali.weekDays[sel.weekdayIndex]} ${sel.day} ${sel.monthName} ${sel.year}',
              style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'امروز',
            onPressed: _goToday,
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'تبدیل تاریخ',
            onPressed: _showConverter,
          ),
        ],
      ),
      body: Column(
        children: [
          // هدر سه‌تقویمی
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${h.day} ${HijriDate.monthNames[h.month - 1]} ${h.year}',
                      style: const TextStyle(
                          fontFamily: 'Vazirmatn', fontSize: 13),
                    ),
                    Text(
                      '${g.day} ${_gMonths[g.month - 1]} ${g.year}',
                      style: const TextStyle(
                          fontFamily: 'Vazirmatn', fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(sel.monthName,
                        style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text('${sel.year}',
                        style: const TextStyle(
                            fontFamily: 'Vazirmatn', fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),

          // ناوبری ماه شمسی
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text(
                    '${_focused.monthName} ${_focused.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (final w in weekDays)
                  Expanded(
                    child: Center(
                      child: Text(w,
                          style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontWeight: FontWeight.bold,
                              color: w == 'ج' ? Colors.redAccent : null)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: leading + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leading) return const SizedBox.shrink();
                final day = index - leading + 1;
                final jDay = Jalali(_focused.year, _focused.month, day);
                final gDay = jDay.toDateTime();
                final hDay = HijriDate.fromGregorian(gDay);
                final occasions = [
                  ...OccasionData.forDay(
                      system: 'jalali', month: jDay.month, day: jDay.day),
                  ...OccasionData.forDay(
                      system: 'gregorian', month: gDay.month, day: gDay.day),
                  ...OccasionData.forDay(
                      system: 'hijri', month: hDay.month, day: hDay.day),
                ];
                final isHoliday = occasions.any((o) => o.isHoliday);
                final isFriday = jDay.weekdayIndex == 6;
                final isToday = gDay.year == DateTime.now().year &&
                    gDay.month == DateTime.now().month &&
                    gDay.day == DateTime.now().day;
                final isSelected = _selectedG != null &&
                    _selectedG!.year == gDay.year &&
                    _selectedG!.month == gDay.month &&
                    _selectedG!.day == gDay.day;

                return InkWell(
                  onTap: () => _onDay(day),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.primary
                          : isToday
                              ? scheme.primary.withValues(alpha: 0.15)
                              : null,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: scheme.primary, width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? scheme.onPrimary
                                : (isHoliday || isFriday)
                                    ? Colors.redAccent
                                    : null,
                          ),
                        ),
                        if (occasions.isNotEmpty)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? scheme.onPrimary
                                  : (isHoliday
                                      ? Colors.redAccent
                                      : scheme.primary),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // نوار مناسبت‌ها
          SafeArea(
            child: ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('مناسبت‌ها',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              trailing: const Icon(Icons.chevron_left),
              onTap: _showOccasions,
            ),
          ),
        ],
      ),
    );
  }
}

/// تبدیل تاریخ شمسی ↔ میلادی ↔ قمری
class _DateConverterSheet extends StatefulWidget {
  const _DateConverterSheet();

  @override
  State<_DateConverterSheet> createState() => _DateConverterSheetState();
}

class _DateConverterSheetState extends State<_DateConverterSheet> {
  String _from = 'jalali';
  final _y = TextEditingController();
  final _m = TextEditingController();
  final _d = TextEditingController();
  String _result = '';

  static const _gMonths = [
    'ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن',
    'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر',
  ];

  @override
  void initState() {
    super.initState();
    final j = Jalali.fromDateTime(DateTime.now());
    _y.text = '${j.year}';
    _m.text = '${j.month}';
    _d.text = '${j.day}';
    _convert();
  }

  @override
  void dispose() {
    _y.dispose();
    _m.dispose();
    _d.dispose();
    super.dispose();
  }

  void _convert() {
    final y = int.tryParse(_y.text) ?? 0;
    final m = int.tryParse(_m.text) ?? 1;
    final d = int.tryParse(_d.text) ?? 1;
    try {
      DateTime g;
      if (_from == 'jalali') {
        g = Jalali(y, m.clamp(1, 12), d.clamp(1, 31)).toDateTime();
      } else if (_from == 'gregorian') {
        g = DateTime(y, m.clamp(1, 12), d.clamp(1, 31));
      } else {
        // تقریبی: جستجوی روز قمری
        g = DateTime.now();
        for (var delta = -800; delta < 800; delta++) {
          final cand = DateTime.now().add(Duration(days: delta));
          final h = HijriDate.fromGregorian(cand);
          if (h.year == y && h.month == m && h.day == d) {
            g = cand;
            break;
          }
        }
      }
      final j = Jalali.fromDateTime(g);
      final h = HijriDate.fromGregorian(g);
      setState(() {
        _result =
            'شمسی: ${j.day} ${j.monthName} ${j.year}\n'
            'قمری: ${h.day} ${HijriDate.monthNames[h.month - 1]} ${h.year}\n'
            'میلادی: ${g.day} ${_gMonths[g.month - 1]} ${g.year}';
      });
    } catch (_) {
      setState(() => _result = 'تاریخ نامعتبر');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('تبدیل تاریخ',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'jalali',
                    label: Text('شمسی',
                        style: TextStyle(fontFamily: 'Vazirmatn'))),
                ButtonSegment(
                    value: 'gregorian',
                    label: Text('میلادی',
                        style: TextStyle(fontFamily: 'Vazirmatn'))),
                ButtonSegment(
                    value: 'hijri',
                    label: Text('قمری',
                        style: TextStyle(fontFamily: 'Vazirmatn'))),
              ],
              selected: {_from},
              onSelectionChanged: (s) {
                setState(() => _from = s.first);
                _convert();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _y,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'سال',
                        labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                    onChanged: (_) => _convert(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _m,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'ماه',
                        labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                    onChanged: (_) => _convert(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _d,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'روز',
                        labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                    onChanged: (_) => _convert(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _result,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Vazirmatn', fontSize: 15, height: 1.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeGalleryScreen extends StatefulWidget {
  const ThemeGalleryScreen({super.key});

  @override
  State<ThemeGalleryScreen> createState() => _ThemeGalleryScreenState();
}

class _ThemeGalleryScreenState extends State<ThemeGalleryScreen> {
  bool _extracting = false;

  Future<void> _pickFromImage() async {
    setState(() => _extracting = true);
    final provider = context.read<ThemeProvider>();
    final ok = await provider.pickImageAndGenerateTheme();
    if (!mounted) return;
    setState(() => _extracting = false);
    final err = provider.lastError;
    String msg;
    if (ok) {
      msg = 'تم از عکس ساخته شد ✓';
    } else if (err == 'cancelled') {
      msg = 'انتخاب عکس لغو شد';
    } else if (err != null && err.isNotEmpty) {
      msg = 'خطا: $err';
    } else {
      msg = 'خطا در ساخت تم از عکس';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Vazirmatn')),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('گالری تم‌ها')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- ساخت تم از عکس ----
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (provider.useCustom && provider.imagePath != null)
                  SizedBox(
                    height: 140,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(provider.imagePath!),
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),
                        const Positioned(
                          bottom: 12,
                          right: 12,
                          child: Text(
                            'تم فعلی از این عکس',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.photo_camera_outlined,
                              color: scheme.primary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'تم از عکس شما',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'یک عکس از گالری انتخاب کنید؛ رنگ‌های اصلی استخراج می‌شوند و تم اپ بر اساس آن ساخته می‌شود.',
                        style: TextStyle(
                            fontFamily: 'Vazirmatn', fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _extracting ? null : _pickFromImage,
                        icon: _extracting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.image_outlined),
                        label: Text(
                          _extracting ? 'در حال ساخت تم...' : 'انتخاب عکس',
                          style: const TextStyle(fontFamily: 'Vazirmatn'),
                        ),
                      ),
                      if (provider.useCustom) ...[
                        const SizedBox(height: 10),
                        // پیش‌نمایش رنگ‌ها
                        Row(
                          children: [
                            _colorDot(provider.customSeed, 'اصلی'),
                            const SizedBox(width: 12),
                            _colorDot(provider.customSecondary, 'فرعی'),
                            const Spacer(),
                            FilterChip(
                              label: Text(
                                provider.customDark ? 'تاریک' : 'روشن',
                                style: const TextStyle(fontFamily: 'Vazirmatn'),
                              ),
                              selected: provider.customDark,
                              onSelected: (v) =>
                                  provider.toggleCustomDark(v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => provider.clearCustomTheme(),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('حذف تم سفارشی',
                              style: TextStyle(fontFamily: 'Vazirmatn')),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'تم‌های آماده',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // ---- شبکه تم‌ها ----
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.15,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: AppThemePresets.all.length,
            itemBuilder: (context, index) {
              final preset = AppThemePresets.all[index];
              final selected =
                  !provider.useCustom && provider.presetId == preset.id;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => provider.setPreset(preset.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? preset.seed
                          : Colors.grey.withValues(alpha: 0.3),
                      width: selected ? 2.5 : 1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        preset.seed.withValues(alpha: 0.85),
                        preset.secondary.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(preset.emoji,
                              style: const TextStyle(fontSize: 22)),
                          const Spacer(),
                          if (selected)
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 22),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        preset.name,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black45)
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          shadows: const [
                            Shadow(blurRadius: 3, color: Colors.black38)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _colorDot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
      ],
    );
  }
}

// ---------- features/settings/presentation/settings_screen.dart ----------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final feedback = context.watch<FeedbackProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ThemeGalleryScreen(),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (themeProvider.useCustom &&
                      themeProvider.imagePath != null)
                    SizedBox(
                      height: 100,
                      child: Image.file(
                        File(themeProvider.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: scheme.primaryContainer,
                          alignment: Alignment.center,
                          child: const Text('🎨',
                              style: TextStyle(fontSize: 36)),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.secondary],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          themeProvider.useCustom
                              ? '🎨'
                              : themeProvider.currentPreset.emoji,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  ListTile(
                    leading:
                        Icon(Icons.palette_outlined, color: scheme.primary),
                    title: const Text('تم و ظاهر',
                        style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      themeProvider.label,
                      style: const TextStyle(
                          fontFamily: 'Vazirmatn', fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_left),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // صدا و ویبره
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.tune),
                  title: Text('بازخورد دکمه‌ها',
                      style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w600)),
                  subtitle: Text('برای ماشین‌حساب و منوها',
                      style:
                          TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                ),
                SwitchListTile(
                  title: const Text('ویبره',
                      style: TextStyle(fontFamily: 'Vazirmatn')),
                  secondary: const Icon(Icons.vibration),
                  value: feedback.hapticEnabled,
                  onChanged: (v) => feedback.setHaptic(v),
                ),
                SwitchListTile(
                  title: const Text('صدای کلیک',
                      style: TextStyle(fontFamily: 'Vazirmatn')),
                  secondary: const Icon(Icons.volume_up_outlined),
                  value: feedback.soundEnabled,
                  onChanged: (v) {
                    feedback.setSound(v);
                    if (v) feedback.playTap();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: scheme.primary),
              title: const Text('درباره اپ',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              subtitle: const Text('نسخه ۱.۰.۰',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: const Color(0xFFFF8A42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                      child: BrandSignature(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- features/calculator/presentation/calculator_screen.dart ----------
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _logic = CalculatorLogic();
  bool _isScientific = false;
  final TextEditingController _textController = TextEditingController();

  void _onButton(String value) {
    if (value.isEmpty) return;
    setState(() {
      if (value == '⌫') {
        _logic.backspace();
      } else if (value == 'MC') {
        _logic.memoryClear();
      } else if (value == 'MR') {
        _logic.memoryRecall();
      } else if (value == 'M+') {
        _logic.memoryAdd();
      } else if (value == 'M-') {
        _logic.memorySubtract();
      } else if (value == 'DEG' || value == 'RAD') {
        _logic.toggleAngleMode();
      } else {
        _logic.input(value);
      }
    });
  }

  Future<void> _copyResult() async {
    final text = _logic.livePreview.isNotEmpty
        ? _logic.livePreview
        : (_logic.result == 'خطا' ? '' : _logic.result);
    if (text.isEmpty || text == '0' && _logic.expression.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('چیزی برای کپی نیست',
              style: TextStyle(fontFamily: 'Vazirmatn')),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('کپی شد: $text',
            style: const TextStyle(fontFamily: 'Vazirmatn')),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showFormulaDialog() {
    _textController.text = _logic.expression;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تایپ دستی فرمول',
              style: TextStyle(fontFamily: 'Vazirmatn')),
          content: TextField(
            controller: _textController,
            autofocus: true,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              hintText: 'مثال: sin(30)+sqrt(16)^2',
              hintStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
            ),
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _logic.calculateFromKeyboard(_textController.text);
                });
                Navigator.pop(context);
              },
              child: const Text('محاسبه',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
          ],
        );
      },
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                      child: Row(
                        children: [
                          const Text('تاریخچه',
                              style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (_logic.history.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _logic.clearHistory());
                                setModal(() {});
                              },
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('پاک کردن',
                                  style: TextStyle(fontFamily: 'Vazirmatn')),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _logic.history.isEmpty
                          ? const Center(
                              child: Text('تاریخچه خالی است',
                                  style: TextStyle(fontFamily: 'Vazirmatn')))
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: _logic.history.length,
                              itemBuilder: (context, index) {
                                final item = _logic.history[index];
                                return Card(
                                  child: ListTile(
                                    title: Text(item['exp']!,
                                        style: const TextStyle(
                                            fontFamily: 'Vazirmatn',
                                            fontSize: 15),
                                        textDirection: TextDirection.ltr),
                                    trailing: Text('= ${item['res']}',
                                        style: const TextStyle(
                                            fontFamily: 'Vazirmatn',
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal)),
                                    onTap: () {
                                      setState(() {
                                        _logic.clear();
                                        _logic.input(item['res']!);
                                      });
                                      Navigator.pop(context);
                                    },
                                    onLongPress: () async {
                                      await Clipboard.setData(
                                          ClipboardData(text: item['res']!));
                                      HapticFeedback.lightImpact();
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showQuickCalc() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _QuickCalcSheet(),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: isLandscape
          ? null
          : AppBar(
              title: const Text('حسابگر من'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.flash_on_outlined),
                  onPressed: _showQuickCalc,
                  tooltip: 'محاسبه سریع',
                ),
                IconButton(
                  icon: const Icon(Icons.school_outlined),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CompoundScreen()));
                  },
                  tooltip: 'جمع مرکب',
                ),
                IconButton(
                  icon: const Icon(Icons.straighten),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ConverterScreen()));
                  },
                  tooltip: 'مبدل واحد',
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard),
                  onPressed: _showFormulaDialog,
                  tooltip: 'تایپ فرمول',
                ),
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: _showHistory,
                  tooltip: 'تاریخچه',
                ),
                IconButton(
                  icon: Icon(
                    _isScientific ? Icons.calculate : Icons.functions,
                    color: AppColors.primary,
                  ),
                  onPressed: () =>
                      setState(() => _isScientific = !_isScientific),
                  tooltip: _isScientific ? 'ساده' : 'علمی',
                ),
              ],
            ),
      body: SafeArea(
        child: isLandscape
            ? _buildLandscapeLayout(isDark)
            : _buildPortraitLayout(isDark),
      ),
    );
  }

  Widget _buildPortraitLayout(bool isDark) {
    final buttons = _isScientific ? _sciButtons : _simpleButtons;
    const crossCount = 4;

    return Column(
      children: [
        _buildDisplay(isDark, 150),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rows = (buttons.length / crossCount).ceil();
              final h = constraints.maxHeight - 8;
              final w = constraints.maxWidth - 16;
              final btnH = (h - (rows - 1) * 5) / rows;
              final btnW = (w - (crossCount - 1) * 5) / crossCount;
              final aspect = btnW / btnH;

              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      childAspectRatio: aspect.clamp(0.85, 1.7),
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                    ),
                    itemCount: buttons.length,
                    itemBuilder: (context, index) {
                      final btn = buttons[index];
                      return _buildBtn(
                        btn['label'] as String,
                        isOp: btn['isOp'] == true,
                        isEq: btn['isEq'] == true,
                        isSci: btn['isSci'] == true,
                        isMemory: btn['isMemory'] == true,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(bool isDark) {
    final rows = <List<Map<String, dynamic>>>[
      [
        {'label': 'MC', 'isMemory': true},
        {'label': 'MR', 'isMemory': true},
        {'label': 'M+', 'isMemory': true},
        {'label': 'M-', 'isMemory': true},
        {'label': 'DEG', 'isSci': true},
        {'label': 'C', 'isOp': true},
      ],
      [
        {'label': 'sin', 'isSci': true},
        {'label': 'cos', 'isSci': true},
        {'label': 'tan', 'isSci': true},
        {'label': 'ln', 'isSci': true},
        {'label': 'log', 'isSci': true},
        {'label': '⌫', 'isOp': true},
      ],
      [
        {'label': '(', 'isOp': true},
        {'label': ')', 'isOp': true},
        {'label': '√', 'isSci': true},
        {'label': '∛', 'isSci': true},
        {'label': '^', 'isOp': true},
        {'label': 'π', 'isSci': true},
      ],
      [
        {'label': '7'},
        {'label': '8'},
        {'label': '9'},
        {'label': '÷', 'isOp': true},
        {'label': 'e', 'isSci': true},
        {'label': '!', 'isSci': true},
      ],
      [
        {'label': '4'},
        {'label': '5'},
        {'label': '6'},
        {'label': '×', 'isOp': true},
        {'label': 'abs', 'isSci': true},
        {'label': '%', 'isSci': true},
      ],
      [
        {'label': '1'},
        {'label': '2'},
        {'label': '3'},
        {'label': '-', 'isOp': true},
        {'label': '0'},
        {'label': '.'},
      ],
    ];
    final lastRow = [
      {'label': '+', 'isOp': true, 'flex': 2},
      {'label': '=', 'isEq': true, 'flex': 4},
    ];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(child: _buildDisplay(isDark, double.infinity)),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.flash_on_outlined, size: 22),
                        onPressed: _showQuickCalc),
                    IconButton(
                        icon: const Icon(Icons.straighten, size: 22),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const ConverterScreen()));
                        }),
                    IconButton(
                        icon: const Icon(Icons.keyboard, size: 22),
                        onPressed: _showFormulaDialog),
                    IconButton(
                        icon: const Icon(Icons.history, size: 22),
                        onPressed: _showHistory),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                children: [
                  for (final row in rows)
                    Expanded(
                      child: Row(
                        children: [
                          for (final btn in row)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: _buildBtn(
                                  btn['label'] as String,
                                  isOp: btn['isOp'] == true,
                                  isEq: btn['isEq'] == true,
                                  isSci: btn['isSci'] == true,
                                  isMemory: btn['isMemory'] == true,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Row(
                      children: [
                        for (final btn in lastRow)
                          Expanded(
                            flex: btn['flex'] as int? ?? 1,
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: _buildBtn(
                                btn['label'] as String,
                                isOp: btn['isOp'] == true,
                                isEq: btn['isEq'] == true,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplay(bool isDark, double height) {
    final preview = _logic.livePreview;
    final showPreview = preview.isNotEmpty && preview != _logic.expression;

    return GestureDetector(
      onLongPress: _copyResult,
      child: Container(
        height: height == double.infinity ? null : height,
        width: double.infinity,
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _logic.memoryDisplay,
                  style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.copy,
                        size: 14,
                        color: isDark ? Colors.grey[600] : Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      _logic.angleMode,
                      style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          color:
                              isDark ? Colors.grey[500] : Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              _logic.expression.isEmpty ? '' : _logic.expression,
              style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 4),
            // نتیجه اصلی یا پیش‌نمایش زنده
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                showPreview
                    ? preview
                    : (_logic.result.isEmpty ? '0' : _logic.result),
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: showPreview
                      ? (isDark ? Colors.tealAccent[100] : Colors.teal[700])
                      : (isDark ? Colors.white : Colors.black87),
                ),
                maxLines: 1,
                textDirection: TextDirection.ltr,
              ),
            ),
            if (showPreview)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'پیش‌نمایش — لمس طولانی برای کپی',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 10,
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(
    String label, {
    bool isOp = false,
    bool isEq = false,
    bool isSci = false,
    bool isMemory = false,
  }) {
    final displayLabel =
        (label == 'DEG' || label == 'RAD') ? _logic.angleMode : label;

    return CalcButton(
      label: displayLabel,
      isOperator: isOp,
      isEqual: isEq,
      isScientific: isSci,
      isMemory: isMemory,
      onTap: () => _onButton(label),
    );
  }

  static const List<Map<String, dynamic>> _simpleButtons = [
    {'label': 'C', 'isOp': true},
    {'label': '⌫', 'isOp': true},
    {'label': '()', 'isOp': true},
    {'label': '÷', 'isOp': true},
    {'label': '7'},
    {'label': '8'},
    {'label': '9'},
    {'label': '×', 'isOp': true},
    {'label': '4'},
    {'label': '5'},
    {'label': '6'},
    {'label': '-', 'isOp': true},
    {'label': '1'},
    {'label': '2'},
    {'label': '3'},
    {'label': '+', 'isOp': true},
    {'label': '0'},
    {'label': '.'},
    {'label': '%', 'isSci': true},
    {'label': '=', 'isEq': true},
  ];

  static const List<Map<String, dynamic>> _sciButtons = [
    {'label': 'MC', 'isMemory': true},
    {'label': 'MR', 'isMemory': true},
    {'label': 'M+', 'isMemory': true},
    {'label': 'M-', 'isMemory': true},
    {'label': 'sin', 'isSci': true},
    {'label': 'cos', 'isSci': true},
    {'label': 'tan', 'isSci': true},
    {'label': 'C', 'isOp': true},
    {'label': 'asin', 'isSci': true},
    {'label': 'acos', 'isSci': true},
    {'label': 'atan', 'isSci': true},
    {'label': '⌫', 'isOp': true},
    {'label': 'ln', 'isSci': true},
    {'label': 'log', 'isSci': true},
    {'label': '√', 'isSci': true},
    {'label': '∛', 'isSci': true},
    {'label': 'x²', 'isSci': true},
    {'label': 'x³', 'isSci': true},
    {'label': '(', 'isOp': true},
    {'label': ')', 'isOp': true},
    {'label': 'π', 'isSci': true},
    {'label': 'e', 'isSci': true},
    {'label': '10ˣ', 'isSci': true},
    {'label': 'eˣ', 'isSci': true},
    {'label': '7'},
    {'label': '8'},
    {'label': '9'},
    {'label': '÷', 'isOp': true},
    {'label': '4'},
    {'label': '5'},
    {'label': '6'},
    {'label': '×', 'isOp': true},
    {'label': '1'},
    {'label': '2'},
    {'label': '3'},
    {'label': '-', 'isOp': true},
    {'label': '0'},
    {'label': '.'},
    {'label': '+', 'isOp': true},
    {'label': '=', 'isEq': true},
  ];
}

/// محاسبه سریع — شبیه ویجت داخل اپ
class _QuickCalcSheet extends StatefulWidget {
  const _QuickCalcSheet();

  @override
  State<_QuickCalcSheet> createState() => _QuickCalcSheetState();
}

class _QuickCalcSheetState extends State<_QuickCalcSheet> {
  final _logic = CalculatorLogic();

  void _tap(String v) {
    setState(() {
      if (v == '⌫') {
        _logic.backspace();
      } else {
        _logic.input(v);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // ترتیب استاندارد چپ‌به‌راست
    const keys = [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['()', '0', '.', '='],
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom + 12,
        top: 12,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text('محاسبه سریع',
              style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _logic.expression.isEmpty ? ' ' : _logic.expression,
                  style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      color: Colors.grey[600]),
                  textDirection: TextDirection.ltr,
                ),
                Text(
                  _logic.livePreview.isNotEmpty
                      ? _logic.livePreview
                      : _logic.result,
                  style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                for (final row in keys)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        for (final k in row)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: SizedBox(
                                height: 52,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: k == '='
                                        ? scheme.primary
                                        : ([
                                            '÷',
                                            '×',
                                            '-',
                                            '+',
                                            '%',
                                            'C',
                                            '⌫',
                                            '()'
                                          ].contains(k)
                                            ? scheme.secondaryContainer
                                            : scheme.surfaceContainerHighest),
                                    foregroundColor: k == '='
                                        ? scheme.onPrimary
                                        : scheme.onSurface,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  onPressed: () => _tap(k),
                                  child: Text(k,
                                      style: const TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- shared/widgets/main_scaffold.dart ----------
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CalculatorScreen(),
    FinanceScreen(),
    ExpensesScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // اگر در حالت افقی و در تب ماشین‌حساب (0) باشیم، منوی پایین را مخفی کن
      bottomNavigationBar: (isLandscape && _currentIndex == 0) 
          ? null 
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                HapticFeedback.selectionClick();
                setState(() => _currentIndex = index);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.calculate_outlined),
                  activeIcon: Icon(Icons.calculate),
                  label: 'ماشین‌حساب',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: Icon(Icons.account_balance_wallet),
                  label: 'مالی',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'هزینه‌ها',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_outlined),
                  activeIcon: Icon(Icons.calendar_month),
                  label: 'تقویم',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'تنظیمات',
                ),
              ],
            ),
    );
  }
}