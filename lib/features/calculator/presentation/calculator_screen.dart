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

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return _logic.history.isEmpty 
          ? const Center(child: Text('تاریخچه خالی است', style: TextStyle(fontFamily: 'Vazirmatn')))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logic.history.length,
              itemBuilder: (context, index) {
                final item = _logic.history[index];
                return ListTile(
                  title: Text(item['exp']!, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 16)),
                  trailing: Text('= ${item['res']}', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                  onTap: () {
                    setState(() {
                      _logic.clear();
                      _logic.input(item['res']!);
                    });
                    Navigator.pop(context);
                  },
                );
              },
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // لیست دکمه‌ها
    final List<Widget> buttons = [
      _buildBtn('MC', isMemory: true), _buildBtn('MR', isMemory: true), _buildBtn('M+', isMemory: true), _buildBtn('M-', isMemory: true),
      _buildBtn('sin', isSci: true), _buildBtn('cos', isSci: true), _buildBtn('tan', isSci: true), _buildBtn('C', isOp: true),
      _buildBtn('ln', isSci: true), _buildBtn('log', isSci: true), _buildBtn('√', isSci: true), _buildBtn('⌫', isOp: true),
      _buildBtn('(', isOp: true), _buildBtn(')', isOp: true), _buildBtn('x²', isSci: true), _buildBtn('^', isOp: true),
      _buildBtn('7'), _buildBtn('8'), _buildBtn('9'), _buildBtn('÷', isOp: true),
      _buildBtn('4'), _buildBtn('5'), _buildBtn('6'), _buildBtn('×', isOp: true),
      _buildBtn('1'), _buildBtn('2'), _buildBtn('3'), _buildBtn('-', isOp: true),
      _buildBtn('0'), _buildBtn('.'), _buildBtn('π', isSci: true), _buildBtn('+', isOp: true),
      _buildBtn('=', isEq: true),
    ];

    return Scaffold(
      appBar: isLandscape ? null : AppBar(
        title: const Text('حسابگر من'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: _showHistory, tooltip: 'تاریخچه'),
          IconButton(
            icon: Icon(_isScientific ? Icons.calculate : Icons.functions, color: AppColors.primary),
            onPressed: () => setState(() => _isScientific = !_isScientific),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildDisplay(isDark),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                // استفاده از Directionality برای چپ‌چین کردن دکمه‌ها در حالت راست‌چین
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: buttons.map((btn) => SizedBox(
                      width: isLandscape 
                          ? (MediaQuery.of(context).size.width / 8) - 12 
                          : (MediaQuery.of(context).size.width / 4) - 12,
                      height: isLandscape ? 50 : 70,
                      child: btn,
                    )).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay(bool isDark) {
    return Expanded(
      flex: 2,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
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
                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Colors.amber, fontWeight: FontWeight.bold),
                ),
                Text(
                  _logic.angleMode,
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _logic.expression.isEmpty ? '0' : _logic.expression,
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 8),
            Text(
              _logic.result,
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 44, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(String label, {bool isOp = false, bool isEq = false, bool isSci = false, bool isMemory = false}) {
    return CalcButton(
      label: label,
      isOperator: isOp,
      isEqual: isEq,
      isScientific: isSci,
      isMemory: isMemory,
      onTap: () => _onButton(label),
    );
  }
}
