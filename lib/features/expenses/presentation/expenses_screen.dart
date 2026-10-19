import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logic/expense_model.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  final _store = ExpenseStore();
  bool _loading = true;
  String? _error;
  late TabController _tab;
  int _filterMonth = DateTime.now().month;
  int _filterYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _store.load().timeout(const Duration(seconds: 5));
    } catch (e) {
      _error = 'خطا در بارگذاری';
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmt(double v) {
    final neg = v < 0;
    final s = v.abs().toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${neg ? '-' : ''}${buf.toString()}';
  }

  Future<void> _openEditor({Expense? existing, bool income = false}) async {
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddSheet(initial: existing, asIncome: income),
    );
    if (result != null) {
      if (existing != null) await _store.remove(existing.id);
      await _store.add(result);
      setState(() {});
    }
  }

  Future<void> _delete(Expense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف', style: TextStyle(fontFamily: 'Vazirmatn')),
        content: Text('«${e.title}» حذف شود؟',
            style: const TextStyle(fontFamily: 'Vazirmatn')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف',
                  style: TextStyle(fontFamily: 'Vazirmatn'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف',
                  style:
                      TextStyle(fontFamily: 'Vazirmatn', color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _store.remove(e.id);
      setState(() {});
    }
  }

  List<Expense> get _monthItems =>
      _store.forMonth(_filterYear, _filterMonth);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final monthExp = _store.expenseInMonth(_filterYear, _filterMonth);
    final monthInc = _store.incomeInMonth(_filterYear, _filterMonth);
    final monthBal = monthInc - monthExp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('هزینه‌ها و درآمد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'بازنشانی',
          ),
          if (_store.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('پاک کردن همه',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    content: const Text('همه تراکنش‌ها حذف شوند؟',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('انصراف',
                              style: TextStyle(fontFamily: 'Vazirmatn'))),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('حذف',
                              style: TextStyle(
                                  fontFamily: 'Vazirmatn', color: Colors.red))),
                    ],
                  ),
                );
                if (ok == true) {
                  await _store.clear();
                  setState(() {});
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
          tabs: const [
            Tab(text: 'خلاصه'),
            Tab(text: 'تراکنش‌ها'),
            Tab(text: 'دسته‌ها'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final choice = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.arrow_upward, color: Colors.red),
                    title: const Text('ثبت هزینه',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    onTap: () => Navigator.pop(ctx, 'expense'),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.arrow_downward, color: Colors.green),
                    title: const Text('ثبت درآمد',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    onTap: () => Navigator.pop(ctx, 'income'),
                  ),
                ],
              ),
            ),
          );
          if (choice == 'expense') await _openEditor(income: false);
          if (choice == 'income') await _openEditor(income: true);
        },
        icon: const Icon(Icons.add),
        label: const Text('جدید', style: TextStyle(fontFamily: 'Vazirmatn')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(fontFamily: 'Vazirmatn')),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _load,
                          child: const Text('تلاش دوباره',
                              style: TextStyle(fontFamily: 'Vazirmatn'))),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // فیلتر ماه
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _filterMonth--;
                                if (_filterMonth < 1) {
                                  _filterMonth = 12;
                                  _filterYear--;
                                }
                              });
                            },
                            icon: const Icon(Icons.chevron_right),
                          ),
                          Expanded(
                            child: Text(
                              '$_filterYear / $_filterMonth',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _filterMonth++;
                                if (_filterMonth > 12) {
                                  _filterMonth = 1;
                                  _filterYear++;
                                }
                              });
                            },
                            icon: const Icon(Icons.chevron_left),
                          ),
                        ],
                      ),
                    ),
                    // کارت خلاصه ماه
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _miniStat('درآمد', _fmt(monthInc),
                                Colors.green, Icons.south_west),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _miniStat('هزینه', _fmt(monthExp),
                                Colors.redAccent, Icons.north_east),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _miniStat(
                              'مانده',
                              _fmt(monthBal),
                              monthBal >= 0 ? scheme.primary : Colors.orange,
                              Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          _buildSummary(scheme, monthExp, monthInc),
                          _buildList(),
                          _buildCategories(scheme),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _miniStat(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(value,
                  style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ColorScheme scheme, double exp, double inc) {
    final items = _monthItems;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: scheme.primary.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            const Text('این ماه تراکنشی نیست',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16)),
            const SizedBox(height: 8),
            const Text('با دکمه «جدید» ثبت کنید',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
          ],
        ),
      );
    }

    final catMap = _store.categoryTotals(
        income: false, year: _filterYear, month: _filterMonth);
    final total = catMap.values.fold(0.0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('توزیع هزینه‌ها',
                    style: TextStyle(
                        fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (catMap.isEmpty)
                  const Text('هزینه‌ای ثبت نشده',
                      style: TextStyle(fontFamily: 'Vazirmatn'))
                else
                  ...catMap.entries.map((e) {
                    final pct = total > 0 ? e.value / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(e.key,
                                  style: const TextStyle(
                                      fontFamily: 'Vazirmatn', fontSize: 13)),
                              const Spacer(),
                              Text(
                                '${_fmt(e.value)} (${(pct * 100).toStringAsFixed(0)}٪)',
                                style: const TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor:
                                  scheme.surfaceContainerHighest,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('تعداد تراکنش این ماه',
                style: TextStyle(fontFamily: 'Vazirmatn')),
            trailing: Text('${items.length}',
                style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    final items = _monthItems;
    if (items.isEmpty) {
      return const Center(
          child: Text('تراکنشی در این ماه نیست',
              style: TextStyle(fontFamily: 'Vazirmatn')));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final e = items[i];
        final color = e.isIncome ? Colors.green : Colors.redAccent;
        return Dismissible(
          key: Key(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) async {
            await _store.remove(e.id);
            setState(() {});
          },
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  e.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                  size: 20,
                ),
              ),
              title: Text(e.title,
                  style: const TextStyle(
                      fontFamily: 'Vazirmatn', fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${e.category} • ${e.date.year}/${e.date.month}/${e.date.day}',
                style:
                    const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
              ),
              trailing: Text(
                '${e.isIncome ? '+' : '-'}${_fmt(e.amount)}',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              onTap: () => _openEditor(existing: e, income: e.isIncome),
              onLongPress: () => _delete(e),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategories(ColorScheme scheme) {
    final expMap = _store.categoryTotals(
        income: false, year: _filterYear, month: _filterMonth);
    final incMap = _store.categoryTotals(
        income: true, year: _filterYear, month: _filterMonth);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        const Text('هزینه‌ها بر اساس دسته',
            style: TextStyle(
                fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (expMap.isEmpty)
          const Text('—', style: TextStyle(fontFamily: 'Vazirmatn'))
        else
          ...expMap.entries.map((e) => Card(
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: Text(e.key,
                      style: const TextStyle(fontFamily: 'Vazirmatn')),
                  trailing: Text(_fmt(e.value),
                      style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)),
                ),
              )),
        const SizedBox(height: 16),
        const Text('درآمدها بر اساس دسته',
            style: TextStyle(
                fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (incMap.isEmpty)
          const Text('—', style: TextStyle(fontFamily: 'Vazirmatn'))
        else
          ...incMap.entries.map((e) => Card(
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(e.key,
                      style: const TextStyle(fontFamily: 'Vazirmatn')),
                  trailing: Text(_fmt(e.value),
                      style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ),
              )),
      ],
    );
  }
}

class _AddSheet extends StatefulWidget {
  final Expense? initial;
  final bool asIncome;
  const _AddSheet({this.initial, this.asIncome = false});

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String _category;
  late bool _isIncome;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _isIncome = i?.isIncome ?? widget.asIncome;
    _title = TextEditingController(text: i?.title ?? '');
    _amount = TextEditingController(
        text: i != null ? i.amount.toStringAsFixed(0) : '');
    _note = TextEditingController(text: i?.note ?? '');
    _category = i?.category ??
        (_isIncome
            ? Expense.incomeCategories.first
            : Expense.expenseCategories.first);
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    final amount = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('عنوان و مبلغ را درست وارد کنید',
              style: TextStyle(fontFamily: 'Vazirmatn'))));
      return;
    }
    Navigator.pop(
      context,
      Expense(
        id: widget.initial?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        amount: amount,
        category: _category,
        date: widget.initial?.date ?? DateTime.now(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        isIncome: _isIncome,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats =
        _isIncome ? Expense.incomeCategories : Expense.expenseCategories;
    if (!cats.contains(_category)) _category = cats.first;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isIncome ? 'ثبت درآمد' : 'ثبت هزینه',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    label: Text('هزینه',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    icon: Icon(Icons.arrow_upward)),
                ButtonSegment(
                    value: true,
                    label: Text('درآمد',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_isIncome},
              onSelectionChanged: (s) => setState(() {
                _isIncome = s.first;
                _category = _isIncome
                    ? Expense.incomeCategories.first
                    : Expense.expenseCategories.first;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              style: const TextStyle(fontFamily: 'Vazirmatn'),
              decoration: InputDecoration(
                labelText: 'عنوان',
                labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              style: const TextStyle(fontFamily: 'Vazirmatn'),
              decoration: InputDecoration(
                labelText: 'مبلغ (تومان)',
                labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'دسته‌بندی',
                labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: cats
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: const TextStyle(fontFamily: 'Vazirmatn'))))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              style: const TextStyle(fontFamily: 'Vazirmatn'),
              decoration: InputDecoration(
                labelText: 'یادداشت (اختیاری)',
                labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('ذخیره',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
