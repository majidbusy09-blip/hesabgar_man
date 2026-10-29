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


/// قالب‌بندی و پارس اعداد ماشین‌حساب (جدا از دقت داخلی double)
///
/// سیاست نمایش:
/// 1) NaN / Infinity → «خطا»
/// 2) عدد صحیح دقیق (در حد epsilon) و |x| < 1e15 → بدون اعشار
/// 3) |x| >= 1e12 یا 0 < |x| < 1e-6 → نماد علمی خوانا
/// 4) در غیر این صورت تا ۱۲ رقم اعشار با حذف صفرهای انتهایی
/// 5) حداکثر حدود ۱۵ رقم معنادار (سقف double)
class CalcNum {
  CalcNum._();

  /// ارقام فارسی/عربی → لاتین (برای فرمول دستی و پارس)
  static String toLatinDigits(String input) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final buf = StringBuffer();
    for (final unit in input.runes) {
      final c = String.fromCharCode(unit);
      final pi = persian.indexOf(c);
      if (pi >= 0) {
        buf.write(pi);
        continue;
      }
      final ai = arabic.indexOf(c);
      if (ai >= 0) {
        buf.write(ai);
        continue;
      }
      if (c == '٫') {
        buf.write('.');
        continue;
      }
      if (c == '٬' || c == '،') {
        continue;
      }
      buf.write(c);
    }
    return buf.toString();
  }

  static const double _intEps = 1e-10;
  static const double _sciHigh = 1e12;
  static const double _sciLow = 1e-6;

  /// جداکننده هزارگان (استاندارد نمایش اعداد در ایران)
  static String groupDigits(String raw) {
    if (raw.isEmpty) return raw;
    final neg = raw.startsWith('-');
    var body = neg ? raw.substring(1) : raw;
    // علمی را دست نزن
    if (body.contains('e') || body.contains('E')) return raw;
    String intPart;
    String? dec;
    if (body.contains('.')) {
      final p = body.split('.');
      intPart = p[0];
      dec = p.length > 1 ? p[1] : '';
    } else {
      intPart = body;
    }
    intPart = intPart.replaceAll(RegExp(r'[^0-9]'), '');
    if (intPart.isEmpty) intPart = '0';
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    var out = buf.toString();
    if (dec != null) out = '$out.$dec';
    return neg ? '-$out' : out;
  }

  /// گروه‌بندی اعداد داخل یک عبارت برای نمایش (۱۰۰۰۰۰۰×۲ → ۱,۰۰۰,۰۰۰×۲)
  static String formatExpression(String expr) {
    if (expr.isEmpty) return expr;
    return expr.replaceAllMapped(RegExp(r'\d+\.?\d*'), (m) {
      return groupDigits(m[0]!);
    });
  }

  static String format(double value) {
    if (value.isNaN || value.isInfinite) return 'خطا';

    if (value == 0) return '0';

    final abs = value.abs();

    final nearest = value.roundToDouble();
    if ((value - nearest).abs() < _intEps && abs < 1e15) {
      return groupDigits(nearest.toInt().toString());
    }

    if (abs >= _sciHigh || abs < _sciLow) {
      return _scientific(value);
    }

    var s = value.toStringAsFixed(12);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return groupDigits(s);
  }

  static String _scientific(double value) {
    var s = value.toStringAsExponential(10);
    final parts = s.split('e');
    if (parts.length != 2) return s;
    var mant = parts[0];
    var exp = parts[1];
    if (mant.contains('.')) {
      mant = mant.replaceAll(RegExp(r'0+$'), '');
      mant = mant.replaceAll(RegExp(r'\.$'), '');
    }
    final sign = exp.startsWith('-') ? '-' : '+';
    final expNum = int.tryParse(exp.replaceAll('+', '').replaceAll('-', '')) ?? 0;
    return '${mant}e$sign$expNum';
  }

  /// پارس امن متن نمایشی (با یا بدون ویرگول) به double
  static double? parse(String text) {
    final t = CalcNum.toLatinDigits(text)
        .trim()
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('،', '');
    if (t.isEmpty || t == 'خطا' || t.startsWith('خطا')) return null;
    return double.tryParse(t);
  }
}

class CalculatorLogic {
  /// موتور محاسبه — مرحله ۲ + ۳ (دقت و نمایش)
  ///
  /// قراردادها:
  /// - توان راست‌پیوند است (مثل کتابخانه): -2^2 → -4 ؛ (-2)^2 → 4
  /// - درصد: هر `n%` یعنی (n/100)؛ مثلاً 50% → 0.5 و 200×50% → 100
  /// - DEG: آرگومان sin/cos/tan به رادیان تبدیل می‌شود؛ خروجی asin/acos/atan به درجه
  /// - دقت داخلی: double (IEEE-754)؛ حدود ۱۵–۱۶ رقم معنادار — ادعای دقت دلخواه نمی‌شود
  /// - نمایش از دقت داخلی جدا است: گردکردن فقط در لایهٔ نمایش

  String _expression = '';
  String _result = '0';
  String _livePreview = '';
  String? _lastError;
  /// آخرین مقدار عددی با دقت کامل double (جدا از متن نمایشی)
  double? _lastValue;
  double _memory = 0;
  bool _isDegree = true;
  int _openParens = 0;
  final List<Map<String, String>> _history = [];
  static const _historyKey = 'calc_history_v1';

  String get expression => _expression;
  /// عبارت با جداکننده هزارگان برای UI
  String get expressionDisplay => CalcNum.formatExpression(_expression);
  String get result => _result;
  String get livePreview => _livePreview;
  String? get lastError => _lastError;
  String get memoryDisplay => _memory != 0 ? 'M' : '';
  String get angleMode => _isDegree ? 'DEG' : 'RAD';
  List<Map<String, String>> get history => List.unmodifiable(_history);

  void toggleAngleMode() {
    _isDegree = !_isDegree;
    _syncDisplay();
  }

  void memoryClear() => _memory = 0;

  void memoryRecall() {
    if (_memory == 0 && _memory != 0.0) return;
    // حتی اگر حافظه صفر باشد MR معمولاً صفر می‌گذارد — اینجا فقط غیرصفر
    if (_memory == 0) return;
    _appendToken(CalcNum.format(_memory));
  }

  void memoryAdd() {
    final v = _currentNumericResult();
    if (v != null) _memory += v;
  }

  void memorySubtract() {
    final v = _currentNumericResult();
    if (v != null) _memory -= v;
  }

  /// مقدار عددی فعلی — اولویت با _lastValue (دقت کامل)، نه متن نمایشی
  double? _currentNumericResult() {
    if (_lastValue != null && _lastValue!.isFinite) return _lastValue;
    if (_result.isNotEmpty &&
        _result != 'خطا' &&
        !_result.startsWith('خطا')) {
      final v = CalcNum.parse(_result);
      if (v != null && v.isFinite) return v;
    }
    return _evaluateRaw(_expression);
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
    _lastError = null;
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
      // اگر عبارت با عدد یا ) تمام شده، تابع را روی همان مقدار اعمال کن
      // مثال: 27 سپس ∛ → cbrt(27)  نه  27×cbrt(
      if (_expression.isNotEmpty &&
          RegExp(r'[0-9)πe]$').hasMatch(_expression)) {
        final wrapped = _wrapLastOperand(functions[value]!);
        if (wrapped != null) {
          _expression = wrapped;
          _openParens = _countOpenParens(_expression);
          _syncDisplay();
          return;
        }
      }
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
      _maybeImplicitMul();
      _expression += '1/(';
      _openParens++;
      _syncDisplay();
      return;
    }
    if (value == 'n!') {
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
        // اجازه منفی بعد از عملگر: 2×-3
        if (value == '-' && last != '-') {
          _expression += '-';
          _syncDisplay();
          return;
        }
        _expression = _expression.substring(0, _expression.length - 1) + value;
        _syncDisplay();
        return;
      }
      if (last == '(' && value != '-') return;
      _expression += value;
      _syncDisplay();
      return;
    }

    if (value == '.') {
      if (!_canAddDot()) return;
    }

    // رقم یا سایر کاراکترها
    if (RegExp(r'^[0-9]$').hasMatch(value)) {
      _maybeImplicitMulBeforeNumber();
    }
    _expression += value;
    _syncDisplay();
  }


  /// آخرین عدد یا پرانتز بسته را داخل تابع قرار می‌دهد: 27 + √ → sqrt(27)
  String? _wrapLastOperand(String funcWithParen) {
    final func = funcWithParen.endsWith('(')
        ? funcWithParen.substring(0, funcWithParen.length - 1)
        : funcWithParen;
    final s = _expression;
    if (s.endsWith(')')) {
      var depth = 0;
      for (var i = s.length - 1; i >= 0; i--) {
        if (s[i] == ')') depth++;
        if (s[i] == '(') {
          depth--;
          if (depth == 0) {
            final inner = s.substring(i);
            final before = s.substring(0, i);
            return '$before$func$inner)';
          }
        }
      }
    }
    final m = RegExp(r'([0-9]+\.?[0-9]*|π|e)$').firstMatch(s);
    if (m != null) {
      final before = s.substring(0, m.start);
      final token = m.group(1)!;
      return '$before$func($token)';
    }
    return null;
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

  void _maybeImplicitMulBeforeNumber() {
    if (_expression.isEmpty) return;
    final last = _expression[_expression.length - 1];
    // 2π3 یا π2 یا e2 → ضرب ضمنی
    if (last == 'π' || last == 'e' || last == ')') {
      _expression += '×';
    }
  }

  bool _canAddDot() {
    final parts = _expression.split(RegExp(r'[+\-×÷*/^()%]'));
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
      if (op == '-' && start > 0) {
        final before = _expression[start - 1];
        if (_isOperator(before) || before == '(') {
          // منفی یک‌طرفه بعد از عملگر → حذف منفی
          _expression =
              '${_expression.substring(0, start)}$num';
        } else {
          _expression =
              '${_expression.substring(0, start)}+$num';
        }
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
      _lastError = null;
      return;
    }
    _tryLiveEval();
  }

  void _tryLiveEval() {
    if (!_looksComplete(_expression)) {
      _livePreview = '';
      return;
    }
    final value = _evaluateRaw(_expression);
    if (value == null) {
      _livePreview = '';
      return;
    }
    _livePreview = CalcNum.format(value);
  }

  /// آیا عبارت برای ارزیابی زنده به‌اندازه کافی کامل به نظر می‌رسد؟
  bool _looksComplete(String expr) {
    if (expr.isEmpty) return false;
    final t = expr.trim();
    final last = t[t.length - 1];
    if (_isOperator(last) || last == '(' || last == '^') return false;
    // پرانتز باز مانده
    if (_countOpenParens(t) > 0) return false;
    return true;
  }

  int _countOpenParens(String s) {
    var n = 0;
    for (final ch in s.split('')) {
      if (ch == '(') n++;
      if (ch == ')' && n > 0) n--;
    }
    return n;
  }

  // ─────────── ارزیابی ───────────

  double? _evaluateRaw(String formula) {
    if (formula.trim().isEmpty) return null;
    try {
      var expr = _prepareExpression(formula);
      if (expr == null) return null;

      final parser = ShuntingYardParser();
      final exp = parser.parse(expr);
      final cm = ContextModel();
      final value = exp.evaluate(EvaluationType.REAL, cm);
      if (value is! num) return null;
      final d = value.toDouble();
      if (d.isNaN || d.isInfinite) return null;
      return d;
    } catch (_) {
      return null;
    }
  }

  /// آماده‌سازی عبارت برای parser
  /// π و e به عدد واقعی تبدیل می‌شوند تا به bind کتابخانه وابسته نباشیم.
  String? _prepareExpression(String input) {
    var expr = CalcNum.toLatinDigits(input).trim();
    if (expr.isEmpty) return null;

    expr = expr
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('٫', '.')
        .replaceAll('٪', '%');

    // π → عدد (قبل از هر پردازش دیگر)
    expr = expr.replaceAll('π', '(${math.pi})');

    // e تنها → عدد (نه exp و نه 1e-5)
    expr = _replaceStandaloneE(expr);

    expr = _insertImplicitMultiplication(expr);

    expr = expr.replaceAllMapped(
      RegExp(r'(\d+\.?\d*)%'),
      (m) => '(${m[1]}/100)',
    );

    expr = expr.replaceAll('√', 'sqrt');
    expr = expr.replaceAll('∛', 'cbrt');

    expr = _replaceFuncBalanced(expr, 'cbrt', (arg) => '(($arg)^(1/3))');

    // log پایه ۱۰ — در بعضی نسخه‌ها فقط ln هست
    expr = _replaceFuncBalanced(
      expr,
      'log',
      (arg) => '(ln($arg)/ln(10))',
    );
    // ln را دست نمی‌زنیم

    // math_expressions از arcsin/arccos/arctan استفاده می‌کند نه asin/acos/atan
    expr = _replaceFuncBalanced(expr, 'asin', (arg) => 'arcsin($arg)');
    expr = _replaceFuncBalanced(expr, 'acos', (arg) => 'arccos($arg)');
    expr = _replaceFuncBalanced(expr, 'atan', (arg) => 'arctan($arg)');

    expr = _replaceFactorials(expr);
    if (expr.contains('!')) return null;

    if (_isDegree) {
      expr = _applyDegreeMode(expr);
    }

    return expr;
  }

  /// جایگزینی e تنها با مقدار عددی e
  String _replaceStandaloneE(String expr) {
    final buf = StringBuffer();
    final eVal = '(${math.e})';
    for (var i = 0; i < expr.length; i++) {
      final ch = expr[i];
      if (ch == 'e' || ch == 'E') {
        final prev = i > 0 ? expr[i - 1] : '';
        final next = i + 1 < expr.length ? expr[i + 1] : '';
        final prevOk =
            prev.isEmpty || !RegExp(r'[a-zA-Z0-9_]').hasMatch(prev);
        final nextOk =
            next.isEmpty || !RegExp(r'[a-zA-Z0-9_(]').hasMatch(next);
        final sci = RegExp(r'[0-9.]').hasMatch(prev) &&
            (next == '+' ||
                next == '-' ||
                RegExp(r'[0-9]').hasMatch(next));
        if (prevOk && nextOk && !sci) {
          buf.write(eVal);
        } else {
          buf.write(ch);
        }
      } else {
        buf.write(ch);
      }
    }
    return buf.toString();
  }

  /// درج × ضمنی در جاهایی که کاربر ننوشته
  String _insertImplicitMultiplication(String expr) {
    // رقم یا ) یا pi یا e قبل از ( یا تابع یا ثابت
    final patterns = <RegExp>[
      // 2(  یا )(  یا π( بعد از نرمال‌سازی (pi)(
      RegExp(r'(\d|\))\s*\('),
      // 2sin 2cos ...
      RegExp(
          r'(\d)\s*(sin|cos|tan|asin|acos|atan|ln|log|sqrt|cbrt|abs|exp|nroot)\s*\('),
      // )sin
      RegExp(
          r'\)\s*(sin|cos|tan|asin|acos|atan|ln|log|sqrt|cbrt|abs|exp)\s*\('),
    ];
    var out = expr;
    // 2( → 2*(
    out = out.replaceAllMapped(RegExp(r'(\d)\s*\('), (m) => '${m[1]}*(');
    // )( → )*(
    out = out.replaceAllMapped(RegExp(r'\)\s*\('), (m) => ')*(');
    // 2sin( → 2*sin(
    out = out.replaceAllMapped(
      RegExp(
          r'(\d)\s*(sin|cos|tan|asin|acos|atan|ln|log|sqrt|cbrt|abs|exp)\s*\('),
      (m) => '${m[1]}*${m[2]}(',
    );
    // )sin( → )*sin(
    out = out.replaceAllMapped(
      RegExp(
          r'\)\s*(sin|cos|tan|asin|acos|atan|ln|log|sqrt|cbrt|abs|exp)\s*\('),
      (m) => ')*${m[1]}(',
    );
    // (pi)( → (pi)*(
    out = out.replaceAllMapped(RegExp(r'\)\s*\('), (m) => ')*(');
    return out;
  }

  /// جایگزینی func(...) با پرانتز متعادل
  String _replaceFuncBalanced(
    String expr,
    String func,
    String Function(String arg) transform,
  ) {
    final name = func;
    var i = 0;
    final buf = StringBuffer();
    while (i < expr.length) {
      if (i + name.length <= expr.length &&
          expr.substring(i, i + name.length) == name &&
          (i + name.length < expr.length && expr[i + name.length] == '(') &&
          (i == 0 || !RegExp(r'[a-zA-Z]').hasMatch(expr[i - 1]))) {
        final open = i + name.length; // index of '('
        final close = _findMatchingParen(expr, open);
        if (close < 0) {
          buf.write(expr[i]);
          i++;
          continue;
        }
        final arg = expr.substring(open + 1, close);
        // آرگومان تو در تو را هم پردازش کن
        final inner = _replaceFuncBalanced(arg, func, transform);
        buf.write(transform(inner));
        i = close + 1;
      } else {
        buf.write(expr[i]);
        i++;
      }
    }
    return buf.toString();
  }

  int _findMatchingParen(String s, int openIdx) {
    var depth = 0;
    for (var i = openIdx; i < s.length; i++) {
      if (s[i] == '(') depth++;
      if (s[i] == ')') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  String _applyDegreeMode(String expr) {
    // اول معکوس‌ها (خروجی رادیان → درجه) — نام‌ها بعد از rename: arcsin/...
    for (final f in ['arcsin', 'arccos', 'arctan']) {
      expr = _replaceFuncBalanced(
        expr,
        f,
        (arg) => '(($f($arg))*180/${math.pi})',
      );
    }
    // بعد sin/cos/tan (آرگومان درجه → رادیان)
    // _replaceFuncBalanced با چک حرف قبلی، arcsin را با sin اشتباه نمی‌گیرد
    for (final f in ['sin', 'cos', 'tan']) {
      expr = _replaceFuncBalanced(
        expr,
        f,
        (arg) => '$f(($arg)*${math.pi}/180)',
      );
    }
    return expr;
  }

  String _replaceFactorials(String expr) {
    // ( … )!
    var out = expr;
    final parenFact = RegExp(r'\(([^()]+)\)!');
    while (parenFact.hasMatch(out)) {
      out = out.replaceFirstMapped(parenFact, (m) {
        final inner = m[1]!;
        final v = _evaluateRaw(inner);
        if (v == null || v < 0 || v != v.roundToDouble() || v > 170) {
          return 'NaN';
        }
        return _factorial(v.round()).toString();
      });
      if (out.contains('NaN')) return out;
    }
    // 12!
    out = out.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
      final n = int.tryParse(m[1]!) ?? -1;
      if (n < 0 || n > 170) return 'NaN';
      return _factorial(n).toString();
    });
    return out;
  }

  double _factorial(int n) {
    if (n <= 1) return 1;
    var r = 1.0;
    for (var i = 2; i <= n; i++) {
      r *= i;
    }
    return r;
  }

  void calculate() {
    _lastError = null;
    if (_expression.trim().isEmpty) return;

    // بستن پرانتزهای باز برای راحتی کاربر
    var expr = _expression;
    final open = _countOpenParens(expr);
    if (open > 0) {
      expr = expr + (')' * open);
    }

    final value = _evaluateRaw(expr);
    if (value == null) {
      _lastError = _diagnoseError(expr);
      _result = _lastError ?? 'خطا';
      _livePreview = '';
      _lastValue = null;
      // عبارت ورودی حفظ می‌شود
      return;
    }

    final calculatedResult = CalcNum.format(value);
    _history.insert(0, {'exp': CalcNum.formatExpression(_expression), 'res': calculatedResult});
    if (_history.length > 100) _history.removeLast();
    _persistHistory();
    _lastValue = value; // دقت کامل برای ادامه محاسبه / حافظه
    _result = calculatedResult;
    _expression = calculatedResult;
    _livePreview = '';
    _openParens = 0;
  }

  String _diagnoseError(String expr) {
    if (expr.contains('/0') || RegExp(r'/\s*0+(\.0+)?\b').hasMatch(expr)) {
      return 'خطا: تقسیم بر صفر';
    }
    if (expr.contains('NaN')) return 'خطا: دامنه نامعتبر';
    if (_countOpenParens(expr) != 0) return 'خطا: پرانتز نامتوازن';
    if (RegExp(r'log10\s*\(\s*0').hasMatch(expr) ||
        RegExp(r'log\s*\(\s*0').hasMatch(expr)) {
      return 'خطا: لگاریتم صفر';
    }
    return 'خطا';
  }

  void calculateFromKeyboard(String formula) {
    // ارقام فارسی/عربی → لاتین قبل از محاسبه
    final normalized = CalcNum.toLatinDigits(formula).trim();
    if (normalized.isEmpty) return;
    _expression = normalized;
    _openParens = _countOpenParens(_expression);
    calculate();
  }


  void backspace() {
    if (_expression.isEmpty) return;
    final last = _expression[_expression.length - 1];
    if (last == '(') _openParens = (_openParens - 1).clamp(0, 99);
    if (last == ')') _openParens++;
    _expression = _expression.substring(0, _expression.length - 1);
    _lastError = null;
    _syncDisplay();
  }

  bool _isOperator(String s) =>
      ['+', '-', '×', '÷', '*', '/', '^'].contains(s);

  void clear() {
    _expression = '';
    _result = '0';
    _livePreview = '';
    _lastError = null;
    _lastValue = null;
    _openParens = 0;
  }

  void clearHistory() {
    _history.clear();
    _persistHistory();
  }

  Future<void> loadHistory() async {
    try {
      final store = await LocalStore.instance;
      final raw = store.getString(_historyKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw);
      if (list is! List) return;
      _history
        ..clear()
        ..addAll(list.whereType<Map>().map((e) => {
              'exp': '${e['exp'] ?? ''}',
              'res': '${e['res'] ?? ''}',
            }));
    } catch (_) {}
  }

  Future<void> _persistHistory() async {
    try {
      final store = await LocalStore.instance;
      await store.setString(_historyKey, jsonEncode(_history));
    } catch (_) {}
  }
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

class _FinanceScreenState extends State<FinanceScreen> {
  bool _moreOpen = false;

  void _openTool(BuildContext context, String title, Widget body) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: body,
        ),
      ),
    );
  }

  void _soon(BuildContext context, String name) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$name به‌زودی در مراحل بعد اضافه می‌شود',
          style: const TextStyle(fontFamily: 'Vazirmatn'),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.surfaceContainerLowest;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('ابزارهای مالی'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'محاسبات مالی، ساده و سریع',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context, 'ابزارهای اصلی'),
          Row(
            children: [
              Expanded(
                child: _FinanceMainTile(
                  icon: Icons.account_balance_outlined,
                  title: 'سود سپرده',
                  onTap: () => _openTool(
                    context,
                    'سود سپرده',
                    const _DepositTab(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FinanceMainTile(
                  icon: Icons.handshake_outlined,
                  title: 'سود وام',
                  onTap: () => _openTool(
                    context,
                    'سود وام',
                    const _LoanTab(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FinanceMainTile(
                  icon: Icons.monetization_on_outlined,
                  title: 'محاسبه طلا',
                  onTap: () => _openTool(
                    context,
                    'محاسبه طلا',
                    const _GoldTab(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _sectionTitle(context, 'محاسبات سریع'),
          _FinanceListGroup(
            children: [
              _FinanceListRow(
                icon: Icons.percent,
                title: 'تخفیف و درصد',
                subtitle: 'محاسبه مبلغ و درصد تخفیف',
                enabled: false,
                onTap: () => _soon(context, 'تخفیف و درصد'),
              ),
              _FinanceListRow(
                icon: Icons.show_chart,
                title: 'سود و زیان فروش',
                subtitle: 'محاسبه سود معامله و حاشیه سود',
                enabled: false,
                onTap: () => _soon(context, 'سود و زیان فروش'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _sectionTitle(context, 'ابزارهای کمکی'),
          _FinanceListGroup(
            children: [
              _FinanceListRow(
                icon: Icons.translate,
                title: 'تبدیل عدد به حروف',
                subtitle: 'تبدیل مبلغ عددی به نوشتار فارسی',
                enabled: false,
                onTap: () => _soon(context, 'تبدیل عدد به حروف'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _moreOpen = !_moreOpen),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune,
                            size: 22,
                            color: scheme.onSurface.withValues(alpha: 0.55)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'گزینه‌های بیشتر',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          _moreOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: scheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ],
                    ),
                    if (!_moreOpen) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'ابزارها و تنظیمات پیشرفته در بخش جمع‌شونده',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ],
                    if (_moreOpen) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'فعلاً ابزار اضافه‌ای اینجا نیست. پس از تأیید مراحل بعد، موارد کم‌کاربرد در این بخش قرار می‌گیرند.',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12.5,
                            height: 1.5,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// کارت مربعی ابزار اصلی (ردیف سه‌تایی)
class _FinanceMainTile extends StatelessWidget {
  const _FinanceMainTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: const Color(0xFFB08D57)),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceListGroup extends StatelessWidget {
  const _FinanceListGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _FinanceListRow extends StatelessWidget {
  const _FinanceListRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: enabled ? 0.9 : 0.55);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.chevron_left,
              color: scheme.onSurface.withValues(alpha: 0.3),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    enabled ? subtitle : '$subtitle — به‌زودی',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11.5,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: scheme.primary.withValues(alpha: 0.85), size: 22),
          ],
        ),
      ),
    );
  }
}

// ---------- سود سپرده (ساده روزانه) ----------
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
    if (!mounted) return;
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
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _field(_principal, 'مبلغ سرمایه‌گذاری', Icons.savings_outlined,
            onChanged: _recalc),
        const SizedBox(height: 14),
        _field(_rate, 'نرخ سود (درصد)', Icons.percent, onChanged: _recalc),
        const SizedBox(height: 20),
        // نتیجه اصلی — سود سالانه
        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: scheme.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              children: [
                Text(
                  'سود سالانه',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _fmtDepositMoney(_r['yearly']!),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'جزئیات سود',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                title: const Text(
                  'سود روزانه',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                ),
                trailing: Text(
                  _fmtDepositMoney(_r['daily']!),
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                title: const Text(
                  'سود ماه ۳۰ روزه',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                ),
                trailing: Text(
                  _fmtDepositMoney(_r['d30']!),
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                title: const Text(
                  'سود ماه ۳۱ روزه',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                ),
                trailing: Text(
                  _fmtDepositMoney(_r['d31']!),
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
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
    if (!mounted) return;
    setState(() {
      _result = FinanceLogic.loanSummary(
        principal: NumFmt.parse(_principal.text),
        annualRatePercent: NumFmt.parse(_rate.text),
        months: NumFmt.parse(_months.text).round(),
      );
    });
  }

  /// با تغییر هر ورودی، نتیجهٔ قبلی دیگر معتبر نیست تا دوباره محاسبه شود.
  void _invalidateResult() {
    if (_result == null) return;
    if (!mounted) return;
    setState(() => _result = null);
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
    final scheme = Theme.of(context).colorScheme;
    final hasResult = _result != null &&
        NumFmt.parse(_principal.text) > 0 &&
        NumFmt.parse(_months.text) > 0;

    Widget sectionTitle(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        sectionTitle('اطلاعات وام'),
        _field(_principal, 'مبلغ وام (تومان)', Icons.payments_outlined,
            onChanged: _invalidateResult),
        const SizedBox(height: 12),
        _field(_rate, 'نرخ سود سالانه (%)', Icons.percent,
            onChanged: _invalidateResult),
        const SizedBox(height: 12),
        _field(_months, 'مدت بازپرداخت (ماه)', Icons.calendar_today_outlined,
            integer: true, onChanged: _invalidateResult),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _calc,
          icon: const Icon(Icons.calculate_outlined),
          label: const Text('محاسبه', style: TextStyle(fontFamily: 'Vazirmatn')),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        if (hasResult) ...[
          const SizedBox(height: 22),
          Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: scheme.primary.withValues(alpha: 0.22),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                children: [
                  Text(
                    'قسط ماهانه',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fmtDepositMoney(_result!['installment']!),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          sectionTitle('جزئیات وام'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: const Text(
                    'مجموع بازپرداخت',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                  ),
                  trailing: Text(
                    _fmtDepositMoney(_result!['total']!),
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: const Text(
                    'مجموع سود وام',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                  ),
                  trailing: Text(
                    _fmtDepositMoney(_result!['interest']!),
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      _loadingPrice = true;
      _priceMsg = 'در حال دریافت نرخ...';
    });

    double? price;
    String? source;

    double? toToman(double v) {
      if (v >= 50000000) return v / 10; // ریال → تومان
      return v;
    }

    double? parseNum(dynamic raw) {
      if (raw == null) return null;
      final s = raw
          .toString()
          .replaceAll(RegExp(r'[^0-9.]'), '')
          .trim();
      final v = double.tryParse(s);
      if (v == null || v <= 0) return null;
      return toToman(v);
    }

    Future<String?> getBody(String url) async {
      try {
        final res = await http
            .get(
              Uri.parse(url),
              headers: {
                'Accept': '*/*',
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
              },
            )
            .timeout(const Duration(seconds: 15));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          return res.body;
        }
      } catch (_) {}
      return null;
    }

    double? parseIranMarket(String body) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is! Map) return null;
        final list = decoded['data'];
        if (list is! List) return null;
        for (final item in list) {
          if (item is Map && item['symbol'] == 'GOLD_18K_IRR') {
            final v = item['price'];
            if (v is num && v > 100000) return v.toDouble();
          }
        }
      } catch (_) {}
      return null;
    }

    double? parseTgjuJson(String body) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is! Map) return null;
        final current = decoded['current'];
        if (current is Map) {
          for (final key in ['geram18', 'tgju_gold_irg18']) {
            final item = current[key];
            if (item is Map) {
              final v = parseNum(item['p']);
              if (v != null && v > 100000) return v;
            }
          }
        }
        final direct = decoded['geram18'];
        if (direct is Map) {
          final v = parseNum(direct['p']);
          if (v != null && v > 100000) return v;
        }
      } catch (_) {}
      return null;
    }

    double? parseTgjuHtml(String body) {
      // price">272,231,000
      final re = RegExp(r'price">\s*([0-9,٬]{8,})');
      final m = re.firstMatch(body);
      if (m != null) {
        final v = parseNum(m.group(1));
        if (v != null && v > 100000) return v;
      }
      return null;
    }

    // ترتیب: CDNهایی که معمولاً در ایران بهتر باز می‌شوند
    final attempts = <(String, String, double? Function(String))>[
      (
        'jsdelivr',
        'https://cdn.jsdelivr.net/gh/iran-market/iran-market.github.io@main/data/popular.json',
        parseIranMarket
      ),
      (
        'fastly',
        'https://fastly.jsdelivr.net/gh/iran-market/iran-market.github.io@main/data/popular.json',
        parseIranMarket
      ),
      (
        'gcore',
        'https://gcore.jsdelivr.net/gh/iran-market/iran-market.github.io@main/data/popular.json',
        parseIranMarket
      ),
      (
        'githack',
        'https://raw.githack.com/iran-market/iran-market.github.io/main/data/popular.json',
        parseIranMarket
      ),
      (
        'github',
        'https://raw.githubusercontent.com/iran-market/iran-market.github.io/main/data/popular.json',
        parseIranMarket
      ),
      (
        'tgju-www',
        'https://www.tgju.org/profile/geram18',
        parseTgjuHtml
      ),
      (
        'tgju-api',
        'https://call1.tgju.org/ajax.json',
        parseTgjuJson
      ),
      (
        'tgju-api2',
        'https://call2.tgju.org/ajax.json',
        parseTgjuJson
      ),
    ];

    for (final a in attempts) {
      final body = await getBody(a.$2);
      if (body == null || body.isEmpty) continue;
      final v = a.$3(body);
      if (v != null && v > 100000) {
        price = v;
        source = a.$1;
        break;
      }
    }

    // اگر کاربر صفحه را بسته، هیچ setState نزن
    if (!mounted) return;

    final fetched = price;
    if (fetched != null && fetched > 0) {
      _price.text = NumFmt.format(fetched);
      _priceMsg =
          'طلای ۱۸ عیار: ${NumFmt.format(fetched)} تومان ($source)';
      _recalc();
      if (mounted) {
        setState(() => _loadingPrice = false);
      }
    } else {
      setState(() {
        _priceMsg =
            'اتصال به سرورهای نرخ برقرار نشد (اینترنت/فیلتر). قیمت را دستی وارد کنید.';
        _loadingPrice = false;
      });
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
    final hasResult =
        NumFmt.parse(_price.text) > 0 && NumFmt.parse(_weight.text) > 0;

    Widget sectionTitle(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        sectionTitle('نرخ روز طلا'),
        TextField(
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩٫٬،]')),
            GroupedNumberFormatter(),
          ],
          onChanged: (_) => _recalc(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 16),
          decoration: InputDecoration(
            labelText: 'قیمت هر گرم طلا (تومان)',
            labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            prefixIcon: _loadingPrice
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
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
          Text(
            _priceMsg!,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              color: scheme.primary,
            ),
          ),
        ],
        const SizedBox(height: 18),
        sectionTitle('وزن'),
        _field(_weight, 'وزن طلا (گرم)', Icons.scale, onChanged: _recalc),
        const SizedBox(height: 18),
        sectionTitle('اجرت، سود و مالیات'),
        Row(
          children: [
            Expanded(
              child: _field(_wage, 'اجرت ساخت (٪)', Icons.build_outlined,
                  onChanged: _recalc),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _field(_profit, 'سود فروشنده (٪)', Icons.trending_up,
                  onChanged: _recalc),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _field(_tax, 'مالیات (٪)', Icons.receipt_long, onChanged: _recalc),
        if (hasResult) ...[
          const SizedBox(height: 22),
          Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: scheme.primary.withValues(alpha: 0.22),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                children: [
                  Text(
                    'قیمت نهایی',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fmtDepositMoney(_r['total']!),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          sectionTitle('جزئیات قیمت'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: const Text(
                    'ارزش طلای خام',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                  ),
                  trailing: Text(
                    _fmtDepositMoney(_r['raw']!),
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: const Text(
                    'اجرت ساخت',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                  ),
                  trailing: Text(
                    _fmtDepositMoney(_r['wage']!),
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: const Text(
                    'سود فروشنده',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                  ),
                  trailing: Text(
                    _fmtDepositMoney(_r['profit']!),
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: const Text(
                    'مالیات',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                  ),
                  trailing: Text(
                    _fmtDepositMoney(_r['tax']!),
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'از دی‌ماه ۱۴۰۰ مالیات بر ارزش افزوده طلا تنها روی اجرت ساخت و سود فروشنده لحاظ می‌شود.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 11,
            height: 1.5,
            color: Colors.grey[600],
          ),
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
      FilteringTextInputFormatter.allow(RegExp(r'[\d.,۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩٫٬،]')),
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
    textAlign: TextAlign.center,
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

/// نمایش پولی نتایج سپرده: فقط برای UI؛ مقدار محاسبه را تغییر نمی‌دهد.
/// به نزدیک‌ترین تومان گرد می‌شود + جداکننده سه‌رقمی.
String _fmtDepositMoney(double v) {
  if (v.isNaN || v.isInfinite) return '—';
  return '${NumFmt.format(v.round())} تومان';
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
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩٫٬،]')),
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

// ---------- راهنمای داخل اپ (با هر قابلیت جدید این متن را به‌روز کن) ----------
class AppGuide {
  static const String title = 'راهنمای حسابگر من';
  static const String versionLabel = '۱.۰.۷';

  /// متن راهنما — خلاصه و قابل‌فهم برای همه
  static const String body = 'حسابگر من سه ماشین‌حساب و چند ابزار روزمره را یک‌جا جمع کرده است.\n\n■ ماشین‌حساب\n• ساده: جمع، تفریق، ضرب، تقسیم و درصد\n• علمی: سینوس، لگاریتم، ریشه، توان و حافظه — با دکمه توابع در بالای صفحه\n• حسابداری: مثل ماشین‌حساب اداری\n  – عدد بزنید، بعد += یا −=\n  – برای تکرار همان عدد، دوباره همان دکمه را بزنید\n  – ضرب و تقسیم: اول عمل، بعد عدد دوم، بعد =\n  – مثال درصد: ۱۰۰ × ۲۵ ٪ = می‌شود ۲۵\n\nآیکون ساعت بالای صفحه، تاریخچه را نشان می‌دهد و تا وقتی خودتان پاک نکنید می‌ماند.\n\n■ مالی و هزینه\n• هزینه‌ها: ثبت خرج با تاریخ شمسی\n• مالی: سود سپرده، وام و قیمت طلا (با به‌روزرسانی آنلاین)\n• مبدل: تبدیل واحدها\n\n■ تقویم\nشمسی، میلادی و قمری در یک صفحه؛ با لمس هر روز مناسبت همان روز را ببینید.\n\n■ تنظیمات و ظاهر\nاز تنظیمات تم، صدا و ویبره را عوض کنید. می‌توانید از یک عکس، تم اختصاصی بسازید.\n\nنکته: اعداد به‌صورت سه‌رقم‌سه‌رقم نمایش داده می‌شوند تا خواندن راحت‌تر باشد.';
}

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(AppGuide.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: scheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'آشنایی سریع با امکانات اپ',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: SelectableText(
                AppGuide.body,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14.5,
                  height: 1.75,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'نسخه ${AppGuide.versionLabel}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

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
              leading: Icon(Icons.menu_book_outlined, color: scheme.primary),
              title: const Text('راهنمای استفاده',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              subtitle: const Text('طرز کار و امکانات اپ',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GuideScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: scheme.primary),
              title: const Text('درباره اپ',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              subtitle: Text('نسخه ${AppGuide.versionLabel}',
                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
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

// ---------- حالت حسابداری (ماشین جمع‌کننده) ----------
/// منطق شبیه ماشین‌حساب نواری / حسابداری:
/// عدد را وارد کن → + یا − بزن → به جمع کل اضافه/کم می‌شود → آماده عدد بعدی.
/// تمرکز: جمع، تفریق، درصد از جمع.
class AccountingLogic {
  double _total = 0;
  String _entry = '';
  bool _entryFresh = true; // بعد از عملگر، رقم جدید جایگزین می‌شود
  bool _showTotal = true;
  /// آخرین عملوند برای تکرار +/− (رفتار ماشین حساب اداری Sharp/Casio)
  double _lastOperand = 0;
  bool _hasLastOperand = false;
  /// آخرین عمل: 1=جمع  -1=تفریق  0=ندارد
  int _lastSign = 0;
  /// عملیات ضرب/تقسیم در انتظار عدد دوم: '×' یا '÷' یا null
  String? _pendingMulDiv;
  /// اگر true باشد، ورود به‌صورت درصد تفسیر می‌شود (÷۱۰۰ هنگام اعمال)
  bool _percentFlag = false;
  final List<Map<String, String>> _tape = [];
  static const _tapeKey = 'acc_tape_v1';

  double get total => _total;
  String get entry => _entry;
  List<Map<String, String>> get tape => List.unmodifiable(_tape);

  /// خط کوچک بالا (جمع جاری)
  String get totalDisplay {
    return CalcNum.format(_total);
  }

  /// عدد بزرگ: هنگام تایپ → ورود؛ وگرنه → جمع
  String get mainDisplay {
    if (!_entryFresh && _entry.isNotEmpty) {
      return _formatEntry(_entry);
    }
    return moneyFormat(_total);
  }

  /// نمایش ورود با جداکننده هزارگان (سه رقم سه رقم)
  String _formatEntry(String e) {
    if (e.isEmpty || e == '-') return e.isEmpty ? '0' : e;
    final neg = e.startsWith('-');
    var raw = neg ? e.substring(1) : e;
    String intPart;
    String? decPart;
    if (raw.contains('.')) {
      final parts = raw.split('.');
      intPart = parts[0].isEmpty ? '0' : parts[0];
      decPart = parts.length > 1 ? parts[1] : '';
    } else {
      intPart = raw;
    }
    final grouped = _groupThousands(intPart);
    final body = decPart != null ? '$grouped.$decPart' : grouped;
    return neg ? '-$body' : body;
  }

  static String _groupThousands(String digits) {
    if (digits.isEmpty) return '0';
    final buf = StringBuffer();
    final len = digits.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  /// نمایش جمع — بدون صفرهای اعشاری اجباری، با جداکننده هزارگان
  String moneyFormat(double v) {
    if (v.isNaN || v.isInfinite) return 'خطا';
    final neg = v < 0;
    // حذف نویز ممیز شناور
    final abs = (v.abs() * 1e10).roundToDouble() / 1e10;
    String body;
    if ((abs - abs.roundToDouble()).abs() < 1e-9 && abs < 1e15) {
      body = _groupThousands(abs.round().toString());
    } else {
      var s = abs.toStringAsFixed(6);
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      final parts = s.split('.');
      body = _groupThousands(parts[0]);
      if (parts.length > 1 && parts[1].isNotEmpty) {
        body = '$body.${parts[1]}';
      }
    }
    return neg ? '($body)' : body;
  }

  void clearTape() {
    _tape.clear();
    _persistTape();
  }

  Future<void> loadTape() async {
    try {
      final store = await LocalStore.instance;
      final raw = store.getString(_tapeKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw);
      if (list is! List) return;
      _tape
        ..clear()
        ..addAll(list.whereType<Map>().map((e) => {
              'op': '${e['op'] ?? ''}',
              'val': '${e['val'] ?? ''}',
              'total': '${e['total'] ?? ''}',
            }));
    } catch (_) {}
  }

  Future<void> _persistTape() async {
    try {
      final store = await LocalStore.instance;
      await store.setString(_tapeKey, jsonEncode(_tape));
    } catch (_) {}
  }

  void _pushTape(String op, String val, String total) {
    _tape.insert(0, {'op': op, 'val': val, 'total': total});
    if (_tape.length > 100) _tape.removeLast();
    _persistTape();
  }

  String get statusLabel {
    if (_pendingMulDiv == '×' && _percentFlag) return '× %';
    if (_pendingMulDiv == '÷' && _percentFlag) return '÷ %';
    if (_pendingMulDiv == '×') return '× …';
    if (_pendingMulDiv == '÷') return '÷ …';
    if (_percentFlag) return '%';
    if (_entry.isNotEmpty && !_entryFresh) return 'ورود';
    if (_hasLastOperand && _lastSign > 0) return 'ثابت +';
    if (_hasLastOperand && _lastSign < 0) return 'ثابت −';
    if (_tape.isEmpty) return 'آماده';
    return 'جمع';
  }

  void inputDigit(String d) {
    if (_entryFresh) {
      _entry = '';
      _entryFresh = false;
      _showTotal = false;
      _percentFlag = false;
    }
    if (d == '000') {
      if (_entry.isEmpty || _entry == '0') {
        _entry = '0';
      } else if (!_entry.contains('.')) {
        _entry += '000';
      }
      return;
    }
    if (d == '.' && _entry.contains('.')) return;
    if (d == '.' && _entry.isEmpty) {
      _entry = '0.';
      return;
    }
    if (d != '.' && _entry == '0') {
      _entry = d;
      return;
    }
    _entry += d;
  }

  void backspace() {
    if (_entryFresh || _entry.isEmpty) return;
    _entry = _entry.substring(0, _entry.length - 1);
    if (_entry.isEmpty) {
      _entryFresh = true;
      _showTotal = true;
    }
  }

  void clearEntry() {
    _entry = '';
    _entryFresh = true;
    _showTotal = true;
  }

  void clearAll() {
    _total = 0;
    _entry = '';
    _entryFresh = true;
    _showTotal = true;
    _lastOperand = 0;
    _hasLastOperand = false;
    _lastSign = 0;
    _pendingMulDiv = null;
    _percentFlag = false;
    _tape.clear();
    _persistTape();
  }

  double? _parseEntry() {
    if (_entry.isEmpty || _entry == '-' || _entry == '.' || _entry == '-.') {
      return null;
    }
    return double.tryParse(_entry);
  }

  void plus() => _applyAddSub(1);

  void minus() => _applyAddSub(-1);

  /// ضرب: فوری اجرا نمی‌شود — صبر برای عدد بعدی و =
  /// الگو: [جمع/عدد] × [عدد] =
  void multiply() {
    _armMulDiv('×');
  }

  /// تقسیم: مثل ضرب، منتظر عدد دوم و =
  void divide() {
    _armMulDiv('÷');
  }

  void _armMulDiv(String op) {
    final typed = _parseEntry();
    if (typed != null) {
      if (_pendingMulDiv != null) {
        _applyMulDiv(typed);
      } else {
        _total = typed;
        // ثبت مبلغ پایه در نوار
        _pushTape('→', moneyFormat(typed), moneyFormat(_total),);
      }
    } else if (_tape.isEmpty && _total != 0) {
      // پایه از جمع قبلی، یک‌بار در نوار بیاید
      _pushTape('→', moneyFormat(_total), moneyFormat(_total));
    }
    _pendingMulDiv = op;
    _percentFlag = false;
    _lastSign = 0;
    _entry = '';
    _entryFresh = true;
    _showTotal = true;
  }

  void _applyMulDiv(double operand) {
    final op = _pendingMulDiv;
    if (op == null) return;
    final wasPercent = _percentFlag;
    final displayOp = wasPercent ? '$op%' : op;
    final rawOperand = operand;
    if (wasPercent) {
      operand = operand / 100.0;
      _percentFlag = false;
    }
    if (op == '×') {
      _total = _total * operand;
    } else if (op == '÷') {
      if (operand == 0) {
        _pendingMulDiv = null;
        _entry = '';
        _entryFresh = true;
        _showTotal = true;
        return;
      }
      _total = _total / operand;
    }
    _pushTape(displayOp, moneyFormat(rawOperand), moneyFormat(_total),);
    _pendingMulDiv = null;
    _lastOperand = rawOperand;
    _hasLastOperand = true;
    _lastSign = 0;
    _entry = '';
    _entryFresh = true;
    _showTotal = true;
  }

  /// رفتار ماشین حساب اداری برای + و − (اعمال فوری + تکرار ثابت)
  void _applyAddSub(int sign) {
    final typed = _parseEntry();
    if (_pendingMulDiv != null) {
      if (typed != null) {
        _applyMulDiv(typed);
      } else {
        _pendingMulDiv = null;
      }
      // بعد از بستن ×÷ با +/− دیگر همان لحظه جمع تکراری نکن
      _entry = '';
      _entryFresh = true;
      _showTotal = true;
      return;
    }

    double operand;
    if (typed != null) {
      operand = typed;
      _lastOperand = operand;
      _hasLastOperand = true;
      _lastSign = sign;
    } else if (_hasLastOperand && _lastSign == sign) {
      operand = _lastOperand;
    } else if (_hasLastOperand) {
      operand = _lastOperand;
      _lastSign = sign;
    } else {
      _entry = '';
      _entryFresh = true;
      _showTotal = true;
      return;
    }

    _total += sign * operand;
    _pushTape(sign > 0 ? '+' : '−', moneyFormat(operand), moneyFormat(_total),);
    _entry = '';
    _entryFresh = true;
    _showTotal = true;
  }

  /// درصد:
  /// - بعد از × یا ÷: عدد ورود به‌عنوان درصد علامت می‌خورد؛ با = اعمال می‌شود
  ///   مثال: ۱۰۰ × ۲۵ ٪ =  →  ۲۵
  /// - بدون عملگر: ورود = درصد از جمع (برای += بعدی)
  void percent() {
    final v = _parseEntry();
    if (v == null) return;
    if (_pendingMulDiv != null) {
      // فقط پرچم درصد؛ نمایش همان عدد می‌ماند
      _percentFlag = true;
      _entryFresh = false;
      _showTotal = false;
      return;
    }
    // بدون ×÷: مقدار ریالیِ درصد از جمع
    if (_total != 0) {
      final result = _total * (v / 100.0);
      _entry = CalcNum.format(result);
    } else {
      _entry = CalcNum.format(v / 100.0);
    }
    _entryFresh = false;
    _showTotal = false;
    _percentFlag = false;
  }

  /// = : اگر × یا ÷ در انتظار است → با عدد واردشده محاسبه کن
  /// وگرنه مثل جمع‌کننده، ورود را با + به جمع اضافه کن
  void totalKey() {
    final v = _parseEntry();
    if (_pendingMulDiv != null) {
      if (v != null) {
        _applyMulDiv(v);
      } else {
        // بدون عدد جدید چیزی روی خودش اعمال نکن
        _pendingMulDiv = null;
        _entry = '';
        _entryFresh = true;
        _showTotal = true;
      }
      return;
    }
    if (v != null) {
      _total += v;
      _lastOperand = v;
      _hasLastOperand = true;
      _lastSign = 1;
      _pushTape('+', moneyFormat(v), moneyFormat(_total),);
    }
    _entry = '';
    _entryFresh = true;
    _showTotal = true;
  }

  void toggleSign() {
    if (_entryFresh) {
      // تغییر علامت جمع کل
      _total = -_total;
      return;
    }
    if (_entry.startsWith('-')) {
      _entry = _entry.substring(1);
    } else if (_entry.isNotEmpty) {
      _entry = '-$_entry';
    }
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _logic = CalculatorLogic();
  final _acc = AccountingLogic();
  /// 0=ساده  1=علمی  2=حسابداری
  int _mode = 0;
  bool get _isScientific => _mode == 1;
  bool get _isAccounting => _mode == 2;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPersistedHistory();
  }

  Future<void> _loadPersistedHistory() async {
    await Future.wait([_logic.loadHistory(), _acc.loadTape()]);
    if (mounted) setState(() {});
  }

  void _onButton(String value) {
    if (value.isEmpty) return;
    setState(() {
      if (_isAccounting) {
        _onAccountingButton(value);
        return;
      }
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

  void _onAccountingButton(String value) {
    // تطبیق امن کاراکترها (بعضی فونت‌ها ×÷ مشابه رندر می‌کنند)
    if (value == 'C') {
      _acc.clearAll();
      return;
    }
    if (value == 'CE') {
      _acc.clearEntry();
      return;
    }
    if (value == '⌫') {
      _acc.backspace();
      return;
    }
    if (value == '+' || value == '+=') {
      _acc.plus();
      return;
    }
    if (value == '-' || value == '−' || value == '−=' || value == '-=') {
      _acc.minus();
      return;
    }
    // ضرب: چند شکل رایج علامت
    if (value == '×' ||
        value == '*' ||
        value == 'x' ||
        value == 'X' ||
        value == '✕' ||
        value == '✖') {
      _acc.multiply();
      return;
    }
    // تقسیم
    if (value == '÷' || value == '/' || value == '⁄') {
      _acc.divide();
      return;
    }
    if (value == '%') {
      _acc.percent();
      return;
    }
    if (value == '=' || value == 'T') {
      _acc.totalKey();
      return;
    }
    if (value == '+/-') {
      _acc.toggleSign();
      return;
    }
    if (value == '.') {
      _acc.inputDigit('.');
      return;
    }
    if (value == '000') {
      _acc.inputDigit('000');
      return;
    }
    if (RegExp(r'^[0-9]$').hasMatch(value)) {
      _acc.inputDigit(value);
    }
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
    final isAcc = _isAccounting;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            final empty = isAcc ? _acc.tape.isEmpty : _logic.history.isEmpty;
            final count = isAcc ? _acc.tape.length : _logic.history.length;
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
                          Text(isAcc ? 'نوار حسابداری' : 'تاریخچه',
                              style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (!empty)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  if (isAcc) {
                                    _acc.clearTape();
                                  } else {
                                    _logic.clearHistory();
                                  }
                                });
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
                      child: empty
                          ? Center(
                              child: Text(
                                  isAcc
                                      ? 'هنوز عملیاتی ثبت نشده'
                                      : 'تاریخچه خالی است',
                                  style: const TextStyle(
                                      fontFamily: 'Vazirmatn')))
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: count,
                              itemBuilder: (context, index) {
                                if (isAcc) {
                                  final item = _acc.tape[index];
                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 36,
                                              child: Text(
                                                item['op'] ?? '',
                                                style: const TextStyle(
                                                  fontFamily: 'Vazirmatn',
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                item['val'] ?? '',
                                                style: const TextStyle(
                                                  fontFamily: 'Vazirmatn',
                                                  fontSize: 15,
                                                ),
                                                textAlign: TextAlign.left,
                                              ),
                                            ),
                                            Text(
                                              item['total'] ?? '',
                                              style: const TextStyle(
                                                fontFamily: 'Vazirmatn',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final item = _logic.history[index];
                                return Card(
                                  child: InkWell(
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
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item['exp'] ?? '',
                                                style: const TextStyle(
                                                  fontFamily: 'Vazirmatn',
                                                  fontSize: 15,
                                                ),
                                                textAlign: TextAlign.left,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              item['res'] ?? '',
                                              style: const TextStyle(
                                                fontFamily: 'Vazirmatn',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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
                    Icons.functions,
                    color: _mode == 1 ? AppColors.primary : null,
                  ),
                  onPressed: () => setState(() {
                    _mode = _mode == 1 ? 0 : 1;
                  }),
                  tooltip: _mode == 1 ? 'ساده' : 'علمی',
                ),
                IconButton(
                  icon: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: _mode == 2 ? AppColors.primary : null,
                  ),
                  onPressed: () => setState(() {
                    _mode = _mode == 2 ? 0 : 2;
                  }),
                  tooltip: _mode == 2 ? 'ساده' : 'حسابداری',
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
    final displayH = _isAccounting ? 150.0 : (_isScientific ? 108.0 : 140.0);

    return Column(
      children: [
        _isAccounting
            ? _buildAccountingDisplay(isDark, displayH)
            : _buildDisplay(isDark, displayH),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: _isAccounting
                  ? _buildButtonGrid(_accountingButtons, crossCount: 4)
                  : _isScientific
                      ? _buildScientificPad()
                      : _buildButtonGrid(_simpleButtons, crossCount: 4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountingDisplay(bool isDark, double height) {
    return GestureDetector(
      onLongPress: () async {
        final text = _acc.moneyFormat(_acc.total);
        await Clipboard.setData(ClipboardData(text: text));
        HapticFeedback.mediumImpact();
      },
      child: Container(
        height: height,
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(8, 6, 8, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'حسابداری',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _acc.statusLabel,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'جمع: ${_acc.moneyFormat(_acc.total)}',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              textDirection: TextDirection.ltr,
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _acc.mainDisplay,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                textDirection: TextDirection.ltr,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// علمی: توابع بالا + صفحه اعداد استاندارد (۷۸۹ / ۴۵۶ / ۱۲۳ / ۰.=)
  Widget _buildScientificPad() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sciH = constraints.maxHeight * 0.40;
        return Column(
          children: [
            SizedBox(
              height: sciH,
              child: _buildButtonGrid(
                _sciFuncButtons,
                crossCount: 4,
                scrollable: true,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _buildButtonGrid(
                _numPadButtons,
                crossCount: 4,
                scrollable: false,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButtonGrid(
    List<Map<String, dynamic>> buttons, {
    required int crossCount,
    bool scrollable = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = (buttons.length / crossCount).ceil().clamp(1, 20);
        const spacing = 5.0;
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        var btnH = (h - (rows - 1) * spacing) / rows;
        if (btnH < 30) btnH = 30;
        final btnW = (w - (crossCount - 1) * spacing) / crossCount;
        var aspect = btnW / btnH;
        if (!aspect.isFinite || aspect <= 0) aspect = 1.2;
        aspect = aspect.clamp(0.5, 3.5);

        return GridView.builder(
          physics: scrollable
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            childAspectRatio: aspect,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
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
        );
      },
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
    final showPreview = preview.isNotEmpty && preview != _logic.expressionDisplay;

    return GestureDetector(
      onLongPress: _copyResult,
      child: Container(
        height: height == double.infinity ? null : height,
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(8, 6, 8, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() => _logic.toggleAngleMode());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _logic.angleMode,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              _logic.expression.isEmpty ? '' : _logic.expressionDisplay,
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

  static const List<Map<String, dynamic>> _accountingButtons = [
    {'label': 'C', 'isOp': true},
    {'label': '⌫', 'isOp': true},
    {'label': '%', 'isSci': true},
    {'label': '÷', 'isOp': true},
    {'label': '7'},
    {'label': '8'},
    {'label': '9'},
    {'label': '×', 'isOp': true},
    {'label': '4'},
    {'label': '5'},
    {'label': '6'},
    {'label': '−=', 'isOp': true},
    {'label': '1'},
    {'label': '2'},
    {'label': '3'},
    {'label': '+=', 'isOp': true},
    {'label': '0'},
    {'label': '000', 'isOp': true},
    {'label': '.'},
    {'label': '=', 'isEq': true},
  ];

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

  /// فقط توابع علمی / حافظه (بالای صفحه)
  static const List<Map<String, dynamic>> _sciFuncButtons = [
    {'label': 'MC', 'isMemory': true},
    {'label': 'MR', 'isMemory': true},
    {'label': 'M+', 'isMemory': true},
    {'label': 'M-', 'isMemory': true},
    {'label': 'sin', 'isSci': true},
    {'label': 'cos', 'isSci': true},
    {'label': 'tan', 'isSci': true},
    {'label': 'DEG', 'isSci': true},
    {'label': 'asin', 'isSci': true},
    {'label': 'acos', 'isSci': true},
    {'label': 'atan', 'isSci': true},
    {'label': 'C', 'isOp': true},
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
  ];

  /// صفحه اعداد استاندارد ۴ستونه
  static const List<Map<String, dynamic>> _numPadButtons = [
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
    {'label': '⌫', 'isOp': true},
    {'label': '+', 'isOp': true},
    {'label': '%', 'isSci': true},
    {'label': '()', 'isOp': true},
    {'label': 'n!', 'isSci': true},
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
                  _logic.expression.isEmpty ? ' ' : _logic.expressionDisplay,
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