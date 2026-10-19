import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../logic/expense_model.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _store = ExpenseStore();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _store.load();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addExpense() async {
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _AddExpenseSheet(),
    );
    if (result != null) {
      await _store.add(result);
      setState(() {});
    }
  }

  Future<void> _delete(Expense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف هزینه', style: TextStyle(fontFamily: 'Vazirmatn')),
        content: Text('«${e.title}» حذف شود؟',
            style: const TextStyle(fontFamily: 'Vazirmatn')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف',
                style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _store.remove(e.id);
      setState(() {});
    }
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('هزینه‌ها'),
        actions: [
          if (_store.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'پاک کردن همه',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('پاک کردن همه',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    content: const Text('همه هزینه‌ها حذف شوند؟',
                        style: TextStyle(fontFamily: 'Vazirmatn')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('انصراف',
                            style: TextStyle(fontFamily: 'Vazirmatn')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('حذف',
                            style: TextStyle(
                                fontFamily: 'Vazirmatn', color: Colors.red)),
                      ),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('هزینه جدید',
            style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // خلاصه
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('مجموع هزینه‌ها',
                          style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              color: Colors.white70,
                              fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        '${_fmt(_store.total)} تومان',
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_store.items.length} مورد',
                        style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            color: Colors.white60,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _store.items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 64,
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              const Text('هنوز هزینه‌ای ثبت نشده',
                                  style: TextStyle(
                                      fontFamily: 'Vazirmatn', fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _store.items.length,
                          itemBuilder: (ctx, i) {
                            final e = _store.items[i];
                            return Dismissible(
                              key: Key(e.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                color: Colors.red,
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) async {
                                await _store.remove(e.id);
                                setState(() {});
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppColors.primary.withValues(alpha: 0.15),
                                    child: Text(
                                      e.category.isNotEmpty
                                          ? e.category[0]
                                          : '؟',
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontFamily: 'Vazirmatn'),
                                    ),
                                  ),
                                  title: Text(e.title,
                                      style: const TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    '${e.category} • ${e.date.year}/${e.date.month.toString().padLeft(2, '0')}/${e.date.day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                        fontFamily: 'Vazirmatn', fontSize: 12),
                                  ),
                                  trailing: Text(
                                    '${_fmt(e.amount)} ت',
                                    style: const TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  onLongPress: () => _delete(e),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _category = Expense.categories.last;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('عنوان و مبلغ را درست وارد کنید',
                style: TextStyle(fontFamily: 'Vazirmatn'))),
      );
      return;
    }
    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: _category,
      date: DateTime.now(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    Navigator.pop(context, expense);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('هزینه جدید',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            items: Expense.categories
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: const TextStyle(fontFamily: 'Vazirmatn')),
                    ))
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
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('ذخیره',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
