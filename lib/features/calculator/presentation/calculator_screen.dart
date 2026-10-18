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
  final TextEditingController _textController = TextEditingController();

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
      } else if (value == 'DEG') {
        _logic.toggleAngleMode();
      } else {
        _logic.input(value);
      }
    });
  }

  void _showFormulaDialog() {
    _textController.text = _logic.expression;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تایپ دستی فرمول', style: TextStyle(fontFamily: 'Vazirmatn')),
          content: TextField(
            controller: _textController,
            autofocus: true,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              hintText: 'مثال: sin(1.5) + 5^2 * 3',
              hintStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
            ),
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _logic.calculateFromKeyboard(_textController.text);
                });
                Navigator.pop(context);
              },
              child: const Text('محاسبه', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
          ],
        );
      },
    );
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

    return Scaffold(
      appBar: isLandscape
          ? null // در حالت افقی نوار بالا حذف می‌شود تا فضا آزاد شود
          : AppBar(
              title: const Text('حسابگر من'),
              actions: [
                IconButton(icon: const Icon(Icons.keyboard), onPressed: _showFormulaDialog, tooltip: 'تایپ فرمول'),
                IconButton(icon: const Icon(Icons.history), onPressed: _showHistory, tooltip: 'تاریخچه'),
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

  // ================= حالت عمودی (Portrait) =================
  Widget _buildPortraitLayout(bool isDark) {
    return Column(
      children: [
        _buildDisplay(isDark, 160),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _isScientific ? _sciButtons.length : _simpleButtons.length,
                itemBuilder: (context, index) {
                  final btnData = _isScientific ? _sciButtons[index] : _simpleButtons[index];
                  return _buildBtn(
                    btnData['label']!,
                    isOp: btnData['isOp'] ?? false,
                    isEq: btnData['isEq'] ?? false,
                    isSci: btnData['isSci'] ?? false,
                    isMemory: btnData['isMemory'] ?? false,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= حالت افقی (Landscape) =================
  Widget _buildLandscapeLayout(bool isDark) {
    return Row(
      children: [
        // سمت راست: نمایشگر و دکمه‌های تنظیمات
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildDisplay(isDark, 120),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(icon: const Icon(Icons.keyboard), onPressed: _showFormulaDialog, tooltip: 'تایپ فرمول'),
                  IconButton(icon: const Icon(Icons.history), onPressed: _showHistory, tooltip: 'تاریخچه'),
                  IconButton(icon: const Icon(Icons.settings_backup_restore), onPressed: () => setState(() => _isScientific = false), tooltip: 'بازگشت'),
                ],
              ),
            ],
          ),
        ),
        
        // سمت چپ: دکمه‌ها (شبکه ۶ ستونه)
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: _landscapeButtons.length,
                itemBuilder: (context, index) {
                  final btnData = _landscapeButtons[index];
                  return _buildBtn(
                    btnData['label']!,
                    isOp: btnData['isOp'] ?? false,
                    isEq: btnData['isEq'] ?? false,
                    isSci: btnData['isSci'] ?? false,
                    isMemory: btnData['isMemory'] ?? false,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplay(bool isDark, double height) {
    return Container(
      height: height,
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
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 4),
          Text(
            _logic.result,
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 36, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
          ),
        ],
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

  final List<Map<String, dynamic>> _simpleButtons = [
    {'label': 'C', 'isOp': true}, {'label': '⌫', 'isOp': true}, {'label': '÷', 'isOp': true}, {'label': '×', 'isOp': true},
    {'label': '7'}, {'label': '8'}, {'label': '9'}, {'label': '-', 'isOp': true},
    {'label': '4'}, {'label': '5'}, {'label': '6'}, {'label': '+', 'isOp': true},
    {'label': '1'}, {'label': '2'}, {'label': '3'}, {'label': '=', 'isEq': true},
    {'label': '0'}, {'label': '.'}, {'label': 'π', 'isSci': true}, {'label': '(', 'isOp': true},
  ];

  final List<Map<String, dynamic>> _sciButtons = [
    {'label': 'MC', 'isMemory': true}, {'label': 'MR', 'isMemory': true}, {'label': 'M+', 'isMemory': true}, {'label': 'M-', 'isMemory': true},
    {'label': 'sin', 'isSci': true}, {'label': 'cos', 'isSci': true}, {'label': 'tan', 'isSci': true}, {'label': 'C', 'isOp': true},
    {'label': 'ln', 'isSci': true}, {'label': 'log', 'isSci': true}, {'label': '√', 'isSci': true}, {'label': '⌫', 'isOp': true},
    {'label': 'x²', 'isSci': true}, {'label': '^', 'isOp': true}, {'label': '(', 'isOp': true}, {'label': ')', 'isOp': true},
    {'label': '7'}, {'label': '8'}, {'label': '9'}, {'label': '÷', 'isOp': true},
    {'label': '4'}, {'label': '5'}, {'label': '6'}, {'label': '×', 'isOp': true},
    {'label': '1'}, {'label': '2'}, {'label': '3'}, {'label': '-', 'isOp': true},
    {'label': '0'}, {'label': '.'}, {'label': 'π', 'isSci': true}, {'label': '+', 'isOp': true},
    {'label': '=', 'isEq': true},
  ];

  final List<Map<String, dynamic>> _landscapeButtons = [
    {'label': 'MC', 'isMemory': true}, {'label': 'MR', 'isMemory': true}, {'label': 'M+', 'isMemory': true}, {'label': 'M-', 'isMemory': true}, {'label': 'DEG', 'isSci': true}, {'label': 'C', 'isOp': true},
    {'label': 'sin', 'isSci': true}, {'label': 'cos', 'isSci': true}, {'label': 'tan', 'isSci': true}, {'label': 'ln', 'isSci': true}, {'label': 'log', 'isSci': true}, {'label': '⌫', 'isOp': true},
    {'label': '(', 'isOp': true}, {'label': ')', 'isOp': true}, {'label': '√', 'isSci': true}, {'label': 'x²', 'isSci': true}, {'label': '^', 'isOp': true}, {'label': 'π', 'isSci': true},
    {'label': '7'}, {'label': '8'}, {'label': '9'}, {'label': '÷', 'isOp': true}, {'label': 'e', 'isSci': true}, {'label': '!', 'isSci': true},
    {'label': '4'}, {'label': '5'}, {'label': '6'}, {'label': '×', 'isOp': true}, {'label': '1/x', 'isSci': true}, {'label': '%', 'isSci': true},
    {'label': '1'}, {'label': '2'}, {'label': '3'}, {'label': '-', 'isOp': true}, {'label': '0'}, {'label': '.'},
    {'label': '+', 'isOp': true}, {'label': '=', 'isEq': true},
  ];
}
