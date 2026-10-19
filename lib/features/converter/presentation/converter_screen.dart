import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logic/unit_data.dart';

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
