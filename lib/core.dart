// ===== core.dart — storage, theme, providers, brand =====
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';


// ---------- core/storage/local_store.dart ----------
/// ذخیره‌سازی فایل‌محور — بدون shared_preferences (پایدارتر روی اندروید)
class LocalStore {
  static LocalStore? _instance;
  static Future<LocalStore> get instance async {
    if (_instance != null) return _instance!;
    final store = LocalStore._();
    await store._init();
    _instance = store;
    return store;
  }

  LocalStore._();

  final Map<String, dynamic> _data = {};
  File? _file;

  Future<void> _init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File(p.join(dir.path, 'hesabgar_prefs.json'));
      if (await _file!.exists()) {
        final raw = await _file!.readAsString();
        if (raw.isNotEmpty) {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          _data.addAll(map);
        }
      }
    } catch (e) {
      debugPrint('LocalStore init: $e');
    }
  }

  Future<void> _flush() async {
    if (_file == null) return;
    try {
      await _file!.writeAsString(jsonEncode(_data), flush: true);
    } catch (e) {
      debugPrint('LocalStore flush: $e');
    }
  }

  String? getString(String key) {
    final v = _data[key];
    return v is String ? v : null;
  }

  int? getInt(String key) {
    final v = _data[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  bool? getBool(String key) {
    final v = _data[key];
    return v is bool ? v : null;
  }

  Future<void> setString(String key, String value) async {
    _data[key] = value;
    await _flush();
  }

  Future<void> setInt(String key, int value) async {
    _data[key] = value;
    await _flush();
  }

  Future<void> setBool(String key, bool value) async {
    _data[key] = value;
    await _flush();
  }

  Future<void> remove(String key) async {
    _data.remove(key);
    await _flush();
  }
}

// ---------- core/theme/app_colors.dart ----------
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2A9D8F);
  static const Color primaryDark = Color(0xFF1E7168);
  static const Color primaryLight = Color(0xFF5FBDB3);

  static const Color secondary = Color(0xFFE76F51);
  static const Color secondaryLight = Color(0xFFF4A261);

  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6B6B6B);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFAAAAAA);

  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
}

// ---------- core/theme/app_theme_presets.dart ----------
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

// ---------- core/theme/app_theme.dart ----------
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Vazirmatn';

  /// ساخت ThemeData از رنگ seed و secondary
  static ThemeData fromColors({
    required Color seed,
    required Color secondary,
    required bool isDark,
  }) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      secondary: secondary,
      brightness: brightness,
    );

    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B6B6B);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.4);
          }
          return null;
        }),
      ),
    );
  }

  static ThemeData fromPreset(AppThemePreset preset) {
    return fromColors(
      seed: preset.seed,
      secondary: preset.secondary,
      isDark: preset.isDark,
    );
  }

  // سازگاری با کد قدیمی
  static ThemeData get light => fromPreset(AppThemePresets.byId('default'));
  static ThemeData get dark => fromColors(
        seed: const Color(0xFF2A9D8F),
        secondary: const Color(0xFFE76F51),
        isDark: true,
      );
}

// ---------- core/providers/feedback_provider.dart ----------
class FeedbackProvider extends ChangeNotifier {
  static const _keyHaptic = 'feedback_haptic';
  static const _keySound = 'feedback_sound';

  bool _haptic = true;
  bool _sound = true;
  bool _loaded = false;

  bool get hapticEnabled => _haptic;
  bool get soundEnabled => _sound;
  bool get loaded => _loaded;

  FeedbackProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final store = await LocalStore.instance;
      _haptic = store.getBool(_keyHaptic) ?? true;
      _sound = store.getBool(_keySound) ?? true;
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  Future<void> setHaptic(bool v) async {
    _haptic = v;
    notifyListeners();
    try {
      final store = await LocalStore.instance;
      await store.setBool(_keyHaptic, v);
    } catch (_) {}
  }

  Future<void> setSound(bool v) async {
    _sound = v;
    notifyListeners();
    try {
      final store = await LocalStore.instance;
      await store.setBool(_keySound, v);
    } catch (_) {}
  }

  void playTap({bool strong = false}) {
    if (_haptic) {
      if (strong) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
    if (_sound) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
      // روی اندروید کلیک سیستم اغلب بی‌صداست؛ ویبره کوتاه جایگزین حس صدا
      if (!_haptic) {
        HapticFeedback.selectionClick();
      }
    }
  }

  void playSelect() {
    if (_haptic) HapticFeedback.selectionClick();
    if (_sound) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }
}

// ---------- core/providers/theme_provider.dart ----------
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

// ---------- shared/widgets/brand_signature.dart ----------
/// امضای بصری اپ — برای اسپلش و درباره
class BrandSignature extends StatelessWidget {
  final bool compact;
  final Color? textColor;

  const BrandSignature({super.key, this.compact = false, this.textColor});

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/brand/app_icon.png',
          width: compact ? 72 : 120,
          height: compact ? 72 : 120,
          errorBuilder: (_, __, ___) => Icon(
            Icons.calculate_rounded,
            size: compact ? 72 : 120,
            color: color,
          ),
        ),
        SizedBox(height: compact ? 12 : 20),
        Text(
          'حسابگر من',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: compact ? 22 : 32,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'هوشمند · مالی · دانش‌آموزی',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: compact ? 12 : 14,
            color: color.withValues(alpha: 0.9),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 16),
          Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ساخته‌شده با دقت برای تو',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: color.withValues(alpha: 0.75),
            ),
          ),
        ],
      ],
    );
  }
}

/// صفحه شروع کوتاه با امضای برند
class BrandSplash extends StatefulWidget {
  final Widget child;
  const BrandSplash({super.key, required this.child});

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    _c.forward();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF9660), Color(0xFFFF6B45)],
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: const Center(child: BrandSignature()),
          ),
        ),
      ),
    );
  }
}
