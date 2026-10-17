import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../logic/calculator_logic.dart';
import 'widgets/calc_button.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _logic = CalculatorLogic();
  bool _isScientific = false;

  void _onButton(String value) {
    setState(() {
      if (value == '⌫') {
        _logic.backspace(); // این متد رو در منطق اضافه کردم
      } else {
        _logic.input(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابگر من'),
        actions: [
          IconButton(
            icon: Icon(
              _isScientific ? Icons.calculate : Icons.functions,
              color: const Color(0xFF2A9D8F),
              size: 28,
            ),
            onPressed: () => setState(() => _isScientific = !_isScientific),
            tooltip: _isScientific ? 'حالت ساده' : 'حالت مهندسی',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // نمایشگر زیبا
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _logic.expression.isEmpty ? '0' : _logic.expression,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _logic.result,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
            ),

            // دکمه‌ها
            Expanded(
              flex: _isScientific ? 6 : 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    if (_isScientific) ...[
                      Expanded(
                        child: Row(
                          children: [
                            _buildSci('sin'), _buildSci('cos'),
                            _buildSci('tan'), _buildSci('log'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            _buildSci('ln'), _buildSci('√'),
                            _buildSci('x²'), _buildSci('π'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // ردیف اول: C, ⌫, (, )
                    Expanded(
                      child: Row(
                        children: [
                          _buildBtn('C', isOperator: true),
                          _buildBtn('⌫', isOperator: true),
                          _buildBtn('(', isOperator: true),
                          _buildBtn(')', isOperator: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ردیف دوم: ÷, 7, 8, 9
                    Expanded(
                      child: Row(
                        children: [
                          _buildBtn('÷', isOperator: true),
                          _buildBtn('7'),
                          _buildBtn('8'),
                          _buildBtn('9'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ردیف سوم: ×, 4, 5, 6
                    Expanded(
                      child: Row(
                        children: [
                          _buildBtn('×', isOperator: true),
                          _buildBtn('4'),
                          _buildBtn('5'),
                          _buildBtn('6'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ردیف چهارم: -, 1, 2, 3
                    Expanded(
                      child: Row(
                        children: [
                          _buildBtn('-', isOperator: true),
                          _buildBtn('1'),
                          _buildBtn('2'),
                          _buildBtn('3'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ردیف پنجم: +, 0, ., =
                    Expanded(
                      child: Row(
                        children: [
                          _buildBtn('+', isOperator: true),
                          _buildBtn('0'),
                          _buildBtn('.'),
                          _buildBtn('=', isEqual: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(String label, {bool isOperator = false, bool isEqual = false, bool isWide = false, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: CalcButton(
        label: label,
        isOperator: isOperator,
        isEqual: isEqual,
        isWide: isWide,
        onTap: () => _onButton(label),
      ),
    );
  }

  Widget _buildSci(String label) {
    return Expanded(
      child: CalcButton(
        label: label,
        isScientific: true,
        onTap: () => _onButton(label),
      ),
    );
  }
}
