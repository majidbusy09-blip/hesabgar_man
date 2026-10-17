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
      _logic.input(value);
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
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() => _isScientific = !_isScientific);
            },
            tooltip: _isScientific ? 'حالت ساده' : 'حالت مهندسی',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _logic.expression.isEmpty ? '0' : _logic.expression,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 22,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _logic.result,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: _isScientific ? 5 : 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (_isScientific) ...[
                      Expanded(
                        child: Row(
                          children: [
                            _buildSci('sin'),
                            const SizedBox(width: 8),
                            _buildSci('cos'),
                            const SizedBox(width: 8),
                            _buildSci('tan'),
                            const SizedBox(width: 8),
                            _buildSci('log'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            _buildSci('ln'),
                            const SizedBox(width: 8),
                            _buildSci('√'),
                            const SizedBox(width: 8),
                            _buildSci('x²'),
                            const SizedBox(width: 8),
                            _buildSci('π'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Expanded(
                      child: Row(
                        children: [
                          _buildBtn('C', isOperator: true),
                          const SizedBox(width: 8),
                          _buildBtn('(', isOperator: true),
                          const SizedBox(width: 8),
                          _buildBtn(')', isOperator: true),
                          const SizedBox(width: 8),
                          _buildBtn('÷', isOperator: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          _buildBtn('7'),
                          const SizedBox(width: 8),
                          _buildBtn('8'),
                          const SizedBox(width: 8),
                          _buildBtn('9'),
                          const SizedBox(width: 8),
                          _buildBtn('×', isOperator: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          _buildBtn('4'),
                          const SizedBox(width: 8),
                          _buildBtn('5'),
                          const SizedBox(width: 8),
                          _buildBtn('6'),
                          const SizedBox(width: 8),
                          _buildBtn('-', isOperator: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          _buildBtn('1'),
                          const SizedBox(width: 8),
                          _buildBtn('2'),
                          const SizedBox(width: 8),
                          _buildBtn('3'),
                          const SizedBox(width: 8),
                          _buildBtn('+', isOperator: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          _buildBtn('0', isWide: true, flex: 2),
                          const SizedBox(width: 8),
                          _buildBtn('.'),
                          const SizedBox(width: 8),
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

  Widget _buildBtn(String label,
      {bool isOperator = false,
      bool isEqual = false,
      bool isWide = false,
      int flex = 1}) {
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
        onTap: () {
          setState(() {
            _logic.input(label);
          });
        },
      ),
    );
  }
}
