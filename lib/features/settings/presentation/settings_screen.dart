import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ظاهر
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined,
                      color: AppColors.primary),
                  title: const Text('ظاهر',
                      style: TextStyle(fontFamily: 'Vazirmatn')),
                  subtitle: Text(
                    'تم فعلی: ${themeProvider.label}',
                    style: const TextStyle(
                        fontFamily: 'Vazirmatn', fontSize: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('روشن',
                            style: TextStyle(fontFamily: 'Vazirmatn')),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('تاریک',
                            style: TextStyle(fontFamily: 'Vazirmatn')),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('سیستم',
                            style: TextStyle(fontFamily: 'Vazirmatn')),
                        icon: Icon(Icons.settings_suggest_outlined),
                      ),
                    ],
                    selected: {themeProvider.mode},
                    onSelectionChanged: (s) {
                      themeProvider.setMode(s.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // درباره
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('درباره اپ',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              subtitle: const Text('نسخه ۱.۰.۰',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'حسابگر من',
                  applicationVersion: '۱.۰.۰',
                  applicationLegalese: 'ماشین‌حساب و ابزارهای مالی شخصی',
                  children: const [
                    SizedBox(height: 12),
                    Text(
                      'شامل ماشین‌حساب علمی، محاسبات مالی (وام، سپرده، مالیات)، ردیاب هزینه و تقویم شمسی.',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.calculate_outlined,
                  color: AppColors.primary),
              title: const Text('امکانات',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              subtitle: const Text(
                'ماشین‌حساب • مالی • هزینه‌ها • تقویم',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
