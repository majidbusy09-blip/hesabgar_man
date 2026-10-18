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

    // دکمه‌های حالت پرتره (۴ ستون)
    final List<Widget> portraitButtons = [
      // ردیف ۱: حافظه و تنظیمات
      _buildBtn('MC', isMemory: true), _buildBtn('MR', isMemory: true), _buildBtn('M+', isMemory: true), _buildBtn('M-', isMemory: true),
      // ردیف ۲: توابع علمی و پاک کردن
      _buildBtn('sin', isSci: true), _buildBtn('cos', isSci: true), _buildBtn('tan', isSci: true), _buildBtn('C', isOp: true),
      // ردیف ۳: توابع پیشرفته
      _buildBtn('ln', isSci: true), _buildBtn('log', isSci: true), _buildBtn('√', isSci: true), _buildBtn('⌫', isOp: true),
      // ردیف ۴: پرانتز و توان
      _buildBtn('(', isOp: true), _buildBtn(')', isOp: true), _buildBtn('x²', isSci: true), _buildBtn('^', isOp: true),
      // ردیف ۵: اعداد ۷ ۸ ۹ و تقسیم
      _buildBtn('7'), _buildBtn('8'), _buildBtn('9'), _buildBtn('÷', isOp: true),
      // ردیف ۶: اعداد ۴ ۵ ۶ و ضرب
      _buildBtn('4'), _buildBtn('5'), _buildBtn('6'), _buildBtn('×', isOp: true),
      // ردیف ۷: اعداد ۱ ۲ ۳ و منها
      _buildBtn('1'), _buildBtn('2'), _buildBtn('3'), _buildBtn('-', isOp: true),
      // ردیف ۸: صفر، ممیز، پی و جمع
      _buildBtn('0'), _buildBtn('.'), _buildBtn('π', isSci: true), _buildBtn('+', isOp: true),
      // ردیف ۹: مساوی
      _buildBtn('=', isEq: true),
    ];

    // دکمه‌های حالت افقی (۶ ستون)
    final List<Widget> landscapeButtons = [
      _buildBtn('MC', isMemory: true), _buildBtn('MR', isMemory: true), _buildBtn('M+', isMemory: true), _buildBtn('M-', isMemory: true), _buildBtn('DEG', isSci: true), _buildBtn('C', isOp: true),
      _buildBtn('sin', isSci: true), _buildBtn('cos', isSci: true), _buildBtn('tan', isSci: true), _buildBtn('ln', isSci: true), _buildBtn('log', isSci: true), _buildBtn('⌫', isOp: true),
      _buildBtn('(', isOp: true), _buildBtn(')', isOp: true), _buildBtn('√', isSci: true), _buildBtn('x²', isSci: true), _buildBtn('^', isOp: true), _buildBtn('π', isSci: true),
      _buildBtn('7'), _buildBtn('8'), _buildBtn('9'), _buildBtn('÷', isOp: true), _buildBtn('e', isSci: true), _buildBtn('!', isSci: true),
      _buildBtn('4'), _buildBtn('5'), _buildBtn('6'), _buildBtn('×', isOp: true), _buildBtn('1/x', isSci: true), _buildBtn('%', isSci: true),
      _buildBtn('1'), _buildBtn('2'), _buildBtn('3'), _buildBtn('-', isOp: true), _buildBtn('0'), _buildBtn('.'),
      _buildBtn('+', isOp: true), _buildBtn('=', isEq: true),
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
            // نمایشگر
            _buildDisplay(isDark),
            
            // دکمه‌ها
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: isLandscape
                    ? _buildGrid(landscapeButtons, 6)
                    : _buildGrid(portraitButtons, 4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Widget> buttons, int crossAxisCount) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.2, // نسبت ابعاد دکمه‌ها
      ),
      itemCount: buttons.length,
      // این خط مهم است: چیدمان از چپ به راست مثل ماشین‌حساب واقعی
      textDirection: TextDirection.ltr, 
      itemBuilder: (context, index) => buttons[index],
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
            // ردیف بالا: نشانگر حافظه و حالت زاویه
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _logic.memoryDisplay,
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Colors.amber, fontWeight: FontWeight.bold),
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
