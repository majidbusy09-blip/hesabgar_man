import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../theme/app_theme.dart';
import '../theme/app_theme_presets.dart';

class ThemeProvider extends ChangeNotifier {
  static const _keyPreset = 'theme_preset_id';
  static const _keyCustomSeed = 'theme_custom_seed';
  static const _keyCustomSecondary = 'theme_custom_secondary';
  static const _keyCustomDark = 'theme_custom_dark';
  static const _keyImagePath = 'theme_image_path';
  static const _keyUseCustom = 'theme_use_custom';

  String _presetId = 'default';
  bool _useCustom = false;
  Color _customSeed = const Color(0xFF2A9D8F);
  Color _customSecondary = const Color(0xFFE76F51);
  bool _customDark = false;
  String? _imagePath;
  bool _loading = true;

  String get presetId => _presetId;
  bool get useCustom => _useCustom;
  String? get imagePath => _imagePath;
  bool get loading => _loading;

  AppThemePreset get currentPreset => AppThemePresets.byId(_presetId);

  ThemeData get theme {
    if (_useCustom) {
      return AppTheme.fromColors(
        seed: _customSeed,
        secondary: _customSecondary,
        isDark: _customDark,
      );
    }
    return AppTheme.fromPreset(currentPreset);
  }

  /// برای سازگاری با MaterialApp: همیشه light می‌گذاریم و theme را خودمان می‌دهیم
  ThemeMode get mode => ThemeMode.light;

  String get label {
    if (_useCustom) return 'سفارشی از عکس';
    return currentPreset.name;
  }

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _presetId = prefs.getString(_keyPreset) ?? 'default';
    _useCustom = prefs.getBool(_keyUseCustom) ?? false;
    _customDark = prefs.getBool(_keyCustomDark) ?? false;
    _imagePath = prefs.getString(_keyImagePath);

    final seedVal = prefs.getInt(_keyCustomSeed);
    final secVal = prefs.getInt(_keyCustomSecondary);
    if (seedVal != null) _customSeed = Color(seedVal);
    if (secVal != null) _customSecondary = Color(secVal);

    // بررسی وجود فایل عکس
    if (_imagePath != null && !File(_imagePath!).existsSync()) {
      _imagePath = null;
      if (_useCustom) {
        _useCustom = false;
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> setPreset(String id) async {
    _presetId = id;
    _useCustom = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPreset, id);
    await prefs.setBool(_keyUseCustom, false);
  }

  /// انتخاب عکس از گالری و استخراج رنگ‌ها
  Future<bool> pickImageAndGenerateTheme() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (xfile == null) return false;

      // کپی به حافظه دائم اپ
      final dir = await getApplicationDocumentsDirectory();
      final dest = p.join(dir.path, 'theme_bg${p.extension(xfile.path)}');
      await File(xfile.path).copy(dest);

      final imageProvider = FileImage(File(dest));
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 12,
        size: const Size(200, 200),
      );

      // انتخاب بهترین رنگ‌ها
      final dominant = palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color ??
          const Color(0xFF2A9D8F);

      final secondary = palette.vibrantColor?.color ??
          palette.lightVibrantColor?.color ??
          palette.darkVibrantColor?.color ??
          palette.mutedColor?.color ??
          dominant;

      // تشخیص روشن/تاریک بودن بر اساس روشنایی dominant
      final luminance = dominant.computeLuminance();
      final isDark = luminance < 0.35;

      _customSeed = dominant;
      _customSecondary = secondary == dominant
          ? Color.lerp(dominant, Colors.orange, 0.4)!
          : secondary;
      _customDark = isDark;
      _imagePath = dest;
      _useCustom = true;

      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyUseCustom, true);
      await prefs.setInt(_keyCustomSeed, _customSeed.value);
      await prefs.setInt(_keyCustomSecondary, _customSecondary.value);
      await prefs.setBool(_keyCustomDark, _customDark);
      await prefs.setString(_keyImagePath, dest);

      return true;
    } catch (e) {
      debugPrint('Theme from image error: $e');
      return false;
    }
  }

  Future<void> clearCustomTheme() async {
    _useCustom = false;
    if (_imagePath != null) {
      try {
        final f = File(_imagePath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    _imagePath = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseCustom, false);
    await prefs.remove(_keyImagePath);
  }

  /// تغییر دستی تاریک/روشن برای تم سفارشی
  Future<void> toggleCustomDark(bool value) async {
    if (!_useCustom) return;
    _customDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCustomDark, value);
  }

  bool get customDark => _customDark;
  Color get customSeed => _customSeed;
  Color get customSecondary => _customSecondary;
}
