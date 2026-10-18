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
              hintText: 'مثال: sin(30) + 5^2 * 3',
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return _logic.history.isEmpty
            ? const SizedBox(
                height: 200,
                child: Center(
                    child: Text('تاریخچه خالی است',
                        style: TextStyle(fontFamily: 'Vazirmatn'))),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _logic.history.length,
                itemBuilder: (context, index) {
                  final item = _logic.history[index];
                  return ListTile(
                    title: Text(item['exp']!,
                        style: const TextStyle(
                            fontFamily: 'Vazirmatn', fontSize: 16),
                        textDirection: TextDirection.ltr),
                    trailing: Text('= ${item['res']}',
                        style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal)),
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
                    icon: const Icon(Icons.keyboard),
                    onPressed: _showFormulaDialog,
                    tooltip: 'تایپ فرمول'),
                IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: _showHistory,
                    tooltip: 'تاریخچه'),
                IconButton(
                  icon: Icon(
                      _isScientific ? Icons.calculate : Icons.functions,
                      color: AppColors.primary),
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

  // ================= حالت عمودی =================
  Widget _buildPortraitLayout(bool isDark) {
    final buttons = _isScientific ? _sciButtons : _simpleButtons;
    const crossCount = 4;

    return Column(
      children: [
        _buildDisplay(isDark, 140),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rows = (buttons.length / crossCount).ceil();
              final availableHeight = constraints.maxHeight - 8;
              final availableWidth = constraints.maxWidth - 16;
              final btnHeight = (availableHeight - (rows - 1) * 6) / rows;
              final btnWidth =
                  (availableWidth - (crossCount - 1) * 6) / crossCount;
              final aspect = btnWidth / btnHeight;

              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      childAspectRatio: aspect.clamp(0.9, 1.6),
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
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

  // ================= حالت افقی =================
  Widget _buildLandscapeLayout(bool isDark) {
    // هر ردیف دقیقاً ۶ دکمه — بدون سلول خالی
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
        {'label': 'x²', 'isSci': true},
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
        {'label': '1/x', 'isSci': true},
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

    // ردیف آخر: + و = (عرض بیشتر برای =)
    final lastRow = [
      {'label': '+', 'isOp': true, 'flex': 2},
      {'label': '=', 'isEq': true, 'flex': 4},
    ];

    return Row(
      children: [
        // سمت راست: نمایشگر + اکشن‌ها
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
                        icon: const Icon(Icons.keyboard, size: 22),
                        onPressed: _showFormulaDialog,
                        tooltip: 'تایپ فرمول'),
                    IconButton(
                        icon: const Icon(Icons.history, size: 22),
                        onPressed: _showHistory,
                        tooltip: 'تاریخچه'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // سمت چپ: دکمه‌ها با Column از Rowها
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                children: [
                  // ۶ ردیف اول
                  for (final row in rows.sublist(0, 6))
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
                  // ردیف آخر: + و = با عرض بیشتر
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
                                isSci: btn['isSci'] == true,
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
    return Container(
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
              Text(
                _logic.angleMode,
                style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : Colors.grey[600]),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              _logic.result,
              style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87),
              maxLines: 1,
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
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

  // ---------- دکمه‌های ساده (۴×۵ = ۲۰) ----------
  static const List<Map<String, dynamic>> _simpleButtons = [
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
    {'label': '-', 'isOp': true},
    {'label': '1'},
    {'label': '2'},
    {'label': '3'},
    {'label': '+', 'isOp': true},
    {'label': '0'},
    {'label': '.'},
    {'label': 'π', 'isSci': true},
    {'label': '=', 'isEq': true},
  ];

  // ---------- دکمه‌های علمی عمودی (۴×۸ = ۳۲) ----------
  static const List<Map<String, dynamic>> _sciButtons = [
    {'label': 'MC', 'isMemory': true},
    {'label': 'MR', 'isMemory': true},
    {'label': 'M+', 'isMemory': true},
    {'label': 'M-', 'isMemory': true},
    {'label': 'sin', 'isSci': true},
    {'label': 'cos', 'isSci': true},
    {'label': 'tan', 'isSci': true},
    {'label': 'C', 'isOp': true},
    {'label': 'ln', 'isSci': true},
    {'label': 'log', 'isSci': true},
    {'label': '√', 'isSci': true},
    {'label': '⌫', 'isOp': true},
    {'label': 'x²', 'isSci': true},
    {'label': '^', 'isOp': true},
    {'label': '(', 'isOp': true},
    {'label': ')', 'isOp': true},
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
