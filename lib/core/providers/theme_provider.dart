import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../storage/local_store.dart';
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
  String? lastError;

  String get presetId => _presetId;
  bool get useCustom => _useCustom;
  String? get imagePath => _imagePath;
  bool get loading => _loading;
  bool get customDark => _customDark;
  Color get customSeed => _customSeed;
  Color get customSecondary => _customSecondary;

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

  ThemeMode get mode => ThemeMode.light;

  String get label {
    if (_useCustom) return 'سفارشی از عکس';
    return currentPreset.name;
  }

  ThemeProvider() {
    _load();
  }

  int _colorToInt(Color c) {
    try {
      // ignore: deprecated_member_use
      return c.value;
    } catch (_) {
      final a = (c.a * 255.0).round() & 0xff;
      final r = (c.r * 255.0).round() & 0xff;
      final g = (c.g * 255.0).round() & 0xff;
      final b = (c.b * 255.0).round() & 0xff;
      return (a << 24) | (r << 16) | (g << 8) | b;
    }
  }

  Future<void> _load() async {
    try {
      final store = await LocalStore.instance;
      _presetId = store.getString(_keyPreset) ?? 'default';
      _useCustom = store.getBool(_keyUseCustom) ?? false;
      _customDark = store.getBool(_keyCustomDark) ?? false;
      _imagePath = store.getString(_keyImagePath);

      final seedVal = store.getInt(_keyCustomSeed);
      final secVal = store.getInt(_keyCustomSecondary);
      if (seedVal != null) _customSeed = Color(seedVal);
      if (secVal != null) _customSecondary = Color(secVal);

      if (_imagePath != null && !File(_imagePath!).existsSync()) {
        _imagePath = null;
        if (_useCustom) {
          // رنگ‌ها را نگه می‌داریم حتی بدون فایل عکس
        }
      }
    } catch (e) {
      debugPrint('ThemeProvider load error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> setPreset(String id) async {
    _presetId = id;
    _useCustom = false;
    notifyListeners();
    try {
      final store = await LocalStore.instance;
      await store.setString(_keyPreset, id);
      await store.setBool(_keyUseCustom, false);
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == ThemeMode.dark) {
      await setPreset('night');
    } else {
      await setPreset('default');
    }
  }

  Future<bool> pickImageAndGenerateTheme() async {
    lastError = null;
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
        requestFullMetadata: false,
      );
      if (xfile == null) {
        lastError = 'cancelled';
        return false;
      }

      final bytes = await xfile.readAsBytes();
      if (bytes.isEmpty) {
        lastError = 'فایل خالی است';
        return false;
      }

      String? destPath;
      try {
        final dir = await getApplicationDocumentsDirectory();
        final ext =
            p.extension(xfile.path).isEmpty ? '.jpg' : p.extension(xfile.path);
        destPath = p.join(dir.path, 'theme_bg$ext');
        await File(destPath).writeAsBytes(bytes, flush: true);
      } catch (e) {
        debugPrint('save image fallback: $e');
        destPath = null;
      }

      final palette = await PaletteGenerator.fromImageProvider(
        MemoryImage(bytes),
        maximumColorCount: 8,
        size: const Size(120, 120),
      );

      final dominant = palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color ??
          const Color(0xFF2A9D8F);

      var secondary = palette.vibrantColor?.color ??
          palette.lightVibrantColor?.color ??
          palette.darkVibrantColor?.color ??
          palette.mutedColor?.color ??
          dominant;

      if (secondary == dominant) {
        secondary = Color.lerp(dominant, Colors.orange, 0.4)!;
      }

      final isDark = dominant.computeLuminance() < 0.35;

      // اول اعمال در حافظه (حتی اگر ذخیره بعداً خطا بدهد)
      _customSeed = dominant;
      _customSecondary = secondary;
      _customDark = isDark;
      _imagePath = destPath;
      _useCustom = true;
      notifyListeners();

      try {
        final store = await LocalStore.instance;
        await store.setBool(_keyUseCustom, true);
        await store.setInt(_keyCustomSeed, _colorToInt(_customSeed));
        await store.setInt(_keyCustomSecondary, _colorToInt(_customSecondary));
        await store.setBool(_keyCustomDark, _customDark);
        if (destPath != null) {
          await store.setString(_keyImagePath, destPath);
        }
      } catch (e) {
        debugPrint('theme save prefs: $e');
        // تم اعمال شده؛ فقط ذخیره ناموفق
      }

      return true;
    } catch (e, st) {
      debugPrint('Theme from image error: $e\n$st');
      lastError = e.toString();
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
    try {
      final store = await LocalStore.instance;
      await store.setBool(_keyUseCustom, false);
      await store.remove(_keyImagePath);
    } catch (_) {}
  }

  Future<void> toggleCustomDark(bool value) async {
    if (!_useCustom) return;
    _customDark = value;
    notifyListeners();
    try {
      final store = await LocalStore.instance;
      await store.setBool(_keyCustomDark, value);
    } catch (_) {}
  }
}
