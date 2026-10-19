import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logic/compound_math.dart';

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
