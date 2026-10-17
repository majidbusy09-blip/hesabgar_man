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
                  title: Text(item['exp']!, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 18)),
                  trailing: Text('= ${item['res']}', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
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

  void _showConverter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مبدل واحد', style: TextStyle(fontFamily: 'Vazirmatn')),
        content: const Text('این بخش در فاز بعدی تکمیل می‌شود.\n(تبدیل دما، طول، وزن و...)', style: TextStyle(fontFamily: 'Vazirmatn')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('باشه')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) _isScientific = true;

    return Scaffold(
      appBar: isLandscape ? null : AppBar(
        title: const Text('حسابگر من'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: _showHistory, tooltip: 'تاریخچه'),
          IconButton(icon: const Icon(Icons.swap_horiz), onPressed: _showConverter, tooltip: 'مبدل واحد'),
          IconButton(
            icon: Icon(_isScientific ? Icons.calculate : Icons.functions, color: AppColors.primary),
            onPressed: () => setState(() => _isScientific = !_isScientific),
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
    return Column(
      children: [
        _buildDisplay(isDark),
        Expanded(
          flex: _isScientific ? 6 : 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                if (_isScientific) ...[
                  Expanded(child: Row(children: [_buildSci('sin'), _buildSci('cos'), _buildSci('tan'), _buildSci('log')])),
                  Expanded(child: Row(children: [_buildSci('ln'), _buildSci('√'), _buildSci('x²'), _buildSci('π')])),
                ],
                Expanded(child: Row(children: [_buildBtn('C', isOperator: true), _buildBtn('⌫', isOperator: true), _buildBtn('(', isOperator: true), _buildBtn(')', isOperator: true)])),
                Expanded(child: Row(children: [_buildBtn('÷', isOperator: true), _buildBtn('7'), _buildBtn('8'), _buildBtn('9')])),
                Expanded(child: Row(children: [_buildBtn('×', isOperator: true), _buildBtn('4'), _buildBtn('5'), _buildBtn('6')])),
                Expanded(child: Row(children: [_buildBtn('-', isOperator: true), _buildBtn('1'), _buildBtn('2'), _buildBtn('3')])),
                Expanded(child: Row(children: [_buildBtn('+', isOperator: true), _buildBtn('0'), _buildBtn('.'), _buildBtn('=', isEqual: true)])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(bool isDark) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildDisplay(isDark),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: Icon(Icons.history, color: isDark ? Colors.white : Colors.black), onPressed: _showHistory),
                    IconButton(icon: Icon(Icons.swap_horiz, color: isDark ? Colors.white : Colors.black), onPressed: _showConverter),
                  ],
                ),
              )
            ],
          ),
        ),
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Expanded(child: Row(children: [_buildSci('sin'), _buildSci('cos'), _buildSci('tan'), _buildBtn('C', isOperator: true)])),
                Expanded(child: Row(children: [_buildSci('ln'), _buildSci('log'), _buildSci('√'), _buildBtn('⌫', isOperator: true)])),
                Expanded(child: Row(children: [_buildBtn('(', isOperator: true), _buildBtn(')'), _buildBtn('÷', isOperator: true), _buildBtn('×', isOperator: true)])),
                Expanded(child: Row(children: [_buildBtn('7'), _buildBtn('8'), _buildBtn('9'), _buildBtn('-', isOperator: true)])),
                Expanded(child: Row(children: [_buildBtn('4'), _buildBtn('5'), _buildBtn('6'), _buildBtn('+', isOperator: true)])),
                Expanded(child: Row(children: [_buildBtn('1'), _buildBtn('2'), _buildBtn('3'), _buildBtn('=', isEqual: true)])),
                Expanded(child: Row(children: [_buildBtn('0'), _buildBtn('.'), _buildBtn('π'), _buildBtn('e', isScientific: true)])),
              ],
            ),
          ),
        ),
      ],
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _logic.expression.isEmpty ? '0' : _logic.expression,
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 8),
            Text(
              _logic.result,
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 40, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(String label, {bool isOperator = false, bool isEqual = false}) {
    return Expanded(child: CalcButton(label: label, isOperator: isOperator, isEqual: isEqual, onTap: () => _onButton(label)));
  }

  Widget _buildSci(String label) {
    return Expanded(child: CalcButton(label: label, isScientific: true, onTap: () => _onButton(label)));
  }
}
