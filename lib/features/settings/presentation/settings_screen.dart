import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/theme_provider.dart';
import 'theme_gallery_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // کارت تم فعلی
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ThemeGalleryScreen(),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (themeProvider.useCustom &&
                      themeProvider.imagePath != null)
                    SizedBox(
                      height: 100,
                      child: Image.file(
                        File(themeProvider.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary,
                            scheme.secondary,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          themeProvider.useCustom
                              ? '🎨'
                              : themeProvider.currentPreset.emoji,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  ListTile(
                    leading: Icon(Icons.palette_outlined, color: scheme.primary),
                    title: const Text('تم و ظاهر',
                        style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      themeProvider.label,
                      style: const TextStyle(
                          fontFamily: 'Vazirmatn', fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_left),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'تم‌های مردانه، زنانه، فصلی و ساخت تم از عکس در گالری تم‌ها',
              style: TextStyle(
                  fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),

          // درباره
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: scheme.primary),
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
                      'شامل ماشین‌حساب علمی، محاسبات مالی، ردیاب هزینه، تقویم شمسی و تم‌های متنوع.',
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
              leading: Icon(Icons.calculate_outlined, color: scheme.primary),
              title: const Text('امکانات',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              subtitle: const Text(
                'ماشین‌حساب • مالی • هزینه‌ها • تقویم • تم‌ها',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
