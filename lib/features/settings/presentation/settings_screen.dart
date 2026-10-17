import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.palette_outlined, color: AppColors.primary),
              title: const Text('ظاهر',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              subtitle: const Text('تم روشن / تاریک / سیستم',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('درباره اپ',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              subtitle: const Text('نسخه ۱.۰.۰',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
