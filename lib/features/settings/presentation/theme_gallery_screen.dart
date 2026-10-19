import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme_presets.dart';
import '../../../core/theme/app_colors.dart';

class ThemeGalleryScreen extends StatefulWidget {
  const ThemeGalleryScreen({super.key});

  @override
  State<ThemeGalleryScreen> createState() => _ThemeGalleryScreenState();
}

class _ThemeGalleryScreenState extends State<ThemeGalleryScreen> {
  bool _extracting = false;

  Future<void> _pickFromImage() async {
    setState(() => _extracting = true);
    final ok = await context.read<ThemeProvider>().pickImageAndGenerateTheme();
    if (!mounted) return;
    setState(() => _extracting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'تم از عکس ساخته شد ✓' : 'انتخاب عکس لغو شد یا خطا رخ داد',
          style: const TextStyle(fontFamily: 'Vazirmatn'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('گالری تم‌ها')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- ساخت تم از عکس ----
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (provider.useCustom && provider.imagePath != null)
                  SizedBox(
                    height: 140,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(provider.imagePath!),
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),
                        const Positioned(
                          bottom: 12,
                          right: 12,
                          child: Text(
                            'تم فعلی از این عکس',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.photo_camera_outlined,
                              color: scheme.primary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'تم از عکس شما',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'یک عکس از گالری انتخاب کنید؛ رنگ‌های اصلی استخراج می‌شوند و تم اپ بر اساس آن ساخته می‌شود.',
                        style: TextStyle(
                            fontFamily: 'Vazirmatn', fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _extracting ? null : _pickFromImage,
                        icon: _extracting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.image_outlined),
                        label: Text(
                          _extracting ? 'در حال ساخت تم...' : 'انتخاب عکس',
                          style: const TextStyle(fontFamily: 'Vazirmatn'),
                        ),
                      ),
                      if (provider.useCustom) ...[
                        const SizedBox(height: 10),
                        // پیش‌نمایش رنگ‌ها
                        Row(
                          children: [
                            _colorDot(provider.customSeed, 'اصلی'),
                            const SizedBox(width: 12),
                            _colorDot(provider.customSecondary, 'فرعی'),
                            const Spacer(),
                            FilterChip(
                              label: Text(
                                provider.customDark ? 'تاریک' : 'روشن',
                                style: const TextStyle(fontFamily: 'Vazirmatn'),
                              ),
                              selected: provider.customDark,
                              onSelected: (v) =>
                                  provider.toggleCustomDark(v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => provider.clearCustomTheme(),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('حذف تم سفارشی',
                              style: TextStyle(fontFamily: 'Vazirmatn')),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'تم‌های آماده',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // ---- شبکه تم‌ها ----
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.15,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: AppThemePresets.all.length,
            itemBuilder: (context, index) {
              final preset = AppThemePresets.all[index];
              final selected =
                  !provider.useCustom && provider.presetId == preset.id;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => provider.setPreset(preset.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? preset.seed
                          : Colors.grey.withValues(alpha: 0.3),
                      width: selected ? 2.5 : 1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        preset.seed.withValues(alpha: 0.85),
                        preset.secondary.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(preset.emoji,
                              style: const TextStyle(fontSize: 22)),
                          const Spacer(),
                          if (selected)
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 22),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        preset.name,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black45)
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          shadows: const [
                            Shadow(blurRadius: 3, color: Colors.black38)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _colorDot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
      ],
    );
  }
}
