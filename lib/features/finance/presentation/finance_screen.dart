import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../logic/finance_logic.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محاسبات مالی'),
        bottom: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
          tabs: const [
            Tab(text: 'قسط وام'),
            Tab(text: 'سود سپرده'),
            Tab(text: 'مالیات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _LoanTab(),
          _DepositTab(),
          _VatTab(),
        ],
      ),
    );
  }
}

// ---------- قسط وام ----------
class _LoanTab extends StatefulWidget {
  const _LoanTab();

  @override
  State<_LoanTab> createState() => _LoanTabState();
}

class _LoanTabState extends State<_LoanTab> {
  final _principal = TextEditingController();
  final _rate = TextEditingController(text: '18');
  final _months = TextEditingController(text: '12');
  Map<String, double>? _result;

  void _calc() {
    final p = double.tryParse(_principal.text.replaceAll(',', '')) ?? 0;
    final r = double.tryParse(_rate.text) ?? 0;
    final m = int.tryParse(_months.text) ?? 0;
    setState(() {
      _result = FinanceLogic.loanSummary(
        principal: p,
        annualRatePercent: r,
        months: m,
      );
    });
  }

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _months.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field(_principal, 'مبلغ وام (تومان)', Icons.payments_outlined),
        const SizedBox(height: 12),
        _field(_rate, 'نرخ سود سالانه (%)', Icons.percent),
        const SizedBox(height: 12),
        _field(_months, 'تعداد اقساط (ماه)', Icons.calendar_today_outlined,
            integer: true),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _calc,
          icon: const Icon(Icons.calculate),
          label: const Text('محاسبه', style: TextStyle(fontFamily: 'Vazirmatn')),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 24),
          _resultCard('قسط ماهانه', _fmt(_result!['installment']!)),
          _resultCard('مجموع پرداختی', _fmt(_result!['total']!)),
          _resultCard('کل سود', _fmt(_result!['interest']!),
              color: AppColors.secondary),
        ],
      ],
    );
  }
}

// ---------- سود سپرده ----------
class _DepositTab extends StatefulWidget {
  const _DepositTab();

  @override
  State<_DepositTab> createState() => _DepositTabState();
}

class _DepositTabState extends State<_DepositTab> {
  final _principal = TextEditingController();
  final _rate = TextEditingController(text: '20');
  final _years = TextEditingController(text: '1');
  double? _final;
  double? _profit;

  void _calc() {
    final p = double.tryParse(_principal.text.replaceAll(',', '')) ?? 0;
    final r = double.tryParse(_rate.text) ?? 0;
    final y = double.tryParse(_years.text) ?? 0;
    final f = FinanceLogic.compoundInterest(
      principal: p,
      annualRatePercent: r,
      years: y,
    );
    setState(() {
      _final = f;
      _profit = f - p;
    });
  }

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _years.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field(_principal, 'مبلغ اولیه (تومان)', Icons.savings_outlined),
        const SizedBox(height: 12),
        _field(_rate, 'نرخ سود سالانه (%)', Icons.percent),
        const SizedBox(height: 12),
        _field(_years, 'مدت (سال)', Icons.timelapse),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _calc,
          icon: const Icon(Icons.calculate),
          label: const Text('محاسبه', style: TextStyle(fontFamily: 'Vazirmatn')),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        if (_final != null) ...[
          const SizedBox(height: 24),
          _resultCard('مبلغ نهایی', _fmt(_final!)),
          _resultCard('سود کسب‌شده', _fmt(_profit!),
              color: AppColors.success),
        ],
      ],
    );
  }
}

// ---------- مالیات ----------
class _VatTab extends StatefulWidget {
  const _VatTab();

  @override
  State<_VatTab> createState() => _VatTabState();
}

class _VatTabState extends State<_VatTab> {
  final _amount = TextEditingController();
  final _rate = TextEditingController(text: '9');
  bool _reverse = false;
  Map<String, double>? _result;

  void _calc() {
    final a = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    final r = double.tryParse(_rate.text) ?? 9;
    setState(() {
      _result = _reverse
          ? FinanceLogic.reverseVat(totalWithVat: a, vatPercent: r)
          : FinanceLogic.vat(amount: a, vatPercent: r);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('محاسبه معکوس (از مبلغ نهایی)',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14)),
          value: _reverse,
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() {
            _reverse = v;
            _result = null;
          }),
        ),
        const SizedBox(height: 8),
        _field(
          _amount,
          _reverse ? 'مبلغ نهایی با مالیات' : 'مبلغ قبل از مالیات',
          Icons.receipt_outlined,
        ),
        const SizedBox(height: 12),
        _field(_rate, 'درصد مالیات', Icons.percent),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _calc,
          icon: const Icon(Icons.calculate),
          label: const Text('محاسبه', style: TextStyle(fontFamily: 'Vazirmatn')),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 24),
          _resultCard('مبلغ خالص', _fmt(_result!['net']!)),
          _resultCard('مالیات', _fmt(_result!['tax']!),
              color: AppColors.secondary),
          _resultCard('مبلغ نهایی', _fmt(_result!['total']!)),
        ],
      ],
    );
  }
}

// ---------- ویجت‌های مشترک ----------
Widget _field(TextEditingController c, String label, IconData icon,
    {bool integer = false}) {
  return TextField(
    controller: c,
    keyboardType: TextInputType.numberWithOptions(decimal: !integer),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
    ],
    style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 16),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Vazirmatn'),
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
    ),
  );
}

Widget _resultCard(String title, String value, {Color? color}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      title: Text(title,
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14)),
      trailing: Text(
        value,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color ?? AppColors.primary,
        ),
      ),
    ),
  );
}

String _fmt(double v) {
  if (v.isNaN || v.isInfinite) return '—';
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${buf.toString()} تومان';
}
