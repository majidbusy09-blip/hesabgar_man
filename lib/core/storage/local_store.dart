import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
