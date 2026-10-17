import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محاسبات مالی')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('محاسبات مالی\nبه‌زودی...',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
