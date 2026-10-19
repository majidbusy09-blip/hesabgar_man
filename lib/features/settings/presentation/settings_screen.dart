import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/feedback_provider.dart';
import 'theme_gallery_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final feedback = context.watch<FeedbackProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                        errorBuilder: (_, __, ___) => Container(
                          color: scheme.primaryContainer,
                          alignment: Alignment.center,
                          child: const Text('🎨',
                              style: TextStyle(fontSize: 36)),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.secondary],
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
                    leading:
                        Icon(Icons.palette_outlined, color: scheme.primary),
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
          const SizedBox(height: 12),

          // صدا و ویبره
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.tune),
                  title: Text('بازخورد دکمه‌ها',
                      style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w600)),
                  subtitle: Text('برای ماشین‌حساب و منوها',
                      style:
                          TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                ),
                SwitchListTile(
                  title: const Text('ویبره',
                      style: TextStyle(fontFamily: 'Vazirmatn')),
                  secondary: const Icon(Icons.vibration),
                  value: feedback.hapticEnabled,
                  onChanged: (v) => feedback.setHaptic(v),
                ),
                SwitchListTile(
                  title: const Text('صدای کلیک',
                      style: TextStyle(fontFamily: 'Vazirmatn')),
                  secondary: const Icon(Icons.volume_up_outlined),
                  value: feedback.soundEnabled,
                  onChanged: (v) {
                    feedback.setSound(v);
                    if (v) feedback.playTap();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

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
                      'ماشین‌حساب علمی، مبدل واحد، مالی، هزینه و درآمد، تقویم شمسی و تم‌های متنوع.',
                      style:
                          TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
