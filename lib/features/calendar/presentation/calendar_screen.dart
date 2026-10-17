import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقویم')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('تقویم شمسی\nبه‌زودی...',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
