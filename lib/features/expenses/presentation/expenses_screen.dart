import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('هزینه‌ها')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('ردیاب هزینه\nبه‌زودی...',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
