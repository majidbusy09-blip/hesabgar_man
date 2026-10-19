import 'package:flutter/material.dart';

/// تعریف یک تم آماده
class AppThemePreset {
  final String id;
  final String name;
  final String emoji;
  final Color seed;
  final Color secondary;
  final bool isDark;
  final String description;

  const AppThemePreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.seed,
    required this.secondary,
    this.isDark = false,
    required this.description,
  });
}

class AppThemePresets {
  AppThemePresets._();

  static const List<AppThemePreset> all = [
    // پیش‌فرض
    AppThemePreset(
      id: 'default',
      name: 'پیش‌فرض',
      emoji: '🌿',
      seed: Color(0xFF2A9D8F),
      secondary: Color(0xFFE76F51),
      description: 'سبز فیروزه‌ای کلاسیک',
    ),
    // جنسیتی / شخصیتی
    AppThemePreset(
      id: 'masculine',
      name: 'مردانه',
      emoji: '👔',
      seed: Color(0xFF1B3A4B),
      secondary: Color(0xFFC9A227),
      isDark: true,
      description: 'آبی تیره و طلایی',
    ),
    AppThemePreset(
      id: 'boyish',
      name: 'پسرونه',
      emoji: '⚽',
      seed: Color(0xFF1565C0),
      secondary: Color(0xFFFF6F00),
      description: 'آبی روشن و نارنجی',
    ),
    AppThemePreset(
      id: 'feminine',
      name: 'زنانه',
      emoji: '💐',
      seed: Color(0xFFAD1457),
      secondary: Color(0xFF7B1FA2),
      description: 'صورتی تیره و بنفش',
    ),
    AppThemePreset(
      id: 'girlish',
      name: 'دخترونه',
      emoji: '🎀',
      seed: Color(0xFFEC407A),
      secondary: Color(0xFFAB47BC),
      description: 'صورتی روشن و یاسی',
    ),
    // فصل‌ها
    AppThemePreset(
      id: 'spring',
      name: 'بهاری',
      emoji: '🌸',
      seed: Color(0xFF66BB6A),
      secondary: Color(0xFFF48FB1),
      description: 'سبز ملایم و صورتی گل',
    ),
    AppThemePreset(
      id: 'summer',
      name: 'تابستانی',
      emoji: '☀️',
      seed: Color(0xFFFFB300),
      secondary: Color(0xFF00BCD4),
      description: 'زرد آفتابی و فیروزه‌ای',
    ),
    AppThemePreset(
      id: 'autumn',
      name: 'پاییزی',
      emoji: '🍂',
      seed: Color(0xFFE65100),
      secondary: Color(0xFF6D4C41),
      description: 'نارنجی برگ و قهوه‌ای',
    ),
    AppThemePreset(
      id: 'winter',
      name: 'زمستانی',
      emoji: '❄️',
      seed: Color(0xFF546E7A),
      secondary: Color(0xFF90CAF9),
      isDark: true,
      description: 'خاکستری سرد و آبی یخی',
    ),
    // حس و حال
    AppThemePreset(
      id: 'ocean',
      name: 'اقیانوسی',
      emoji: '🌊',
      seed: Color(0xFF0277BD),
      secondary: Color(0xFF26A69A),
      description: 'آبی دریا و سبز آب',
    ),
    AppThemePreset(
      id: 'sunset',
      name: 'غروب',
      emoji: '🌅',
      seed: Color(0xFFFF5722),
      secondary: Color(0xFFFFC107),
      description: 'نارنجی غروب و طلایی',
    ),
    AppThemePreset(
      id: 'night',
      name: 'شب',
      emoji: '🌙',
      seed: Color(0xFF311B92),
      secondary: Color(0xFF7C4DFF),
      isDark: true,
      description: 'بنفش شب و نئون',
    ),
    AppThemePreset(
      id: 'forest',
      name: 'جنگلی',
      emoji: '🌲',
      seed: Color(0xFF2E7D32),
      secondary: Color(0xFF8D6E63),
      description: 'سبز جنگل و چوب',
    ),
    AppThemePreset(
      id: 'lavender',
      name: 'اسطوخودوس',
      emoji: '💜',
      seed: Color(0xFF9575CD),
      secondary: Color(0xFFF8BBD0),
      description: 'بنفش ملایم و صورتی',
    ),
    AppThemePreset(
      id: 'minimal',
      name: 'مینیمال',
      emoji: '⚪',
      seed: Color(0xFF424242),
      secondary: Color(0xFF9E9E9E),
      description: 'خاکستری ساده و تمیز',
    ),
    AppThemePreset(
      id: 'rose_gold',
      name: 'رزگلد',
      emoji: '✨',
      seed: Color(0xFFB76E79),
      secondary: Color(0xFFD4A5A5),
      description: 'رزگلد لوکس',
    ),
  ];

  static AppThemePreset byId(String id) {
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }
}
