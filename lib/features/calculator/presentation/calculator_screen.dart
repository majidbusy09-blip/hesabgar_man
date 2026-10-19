import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../logic/calculator_logic.dart';
import 'widgets/calc_button.dart';
import '../../converter/presentation/converter_screen.dart';

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
