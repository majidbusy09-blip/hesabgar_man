import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final prefs = await SharedPreferences.getInstance();
      _haptic = prefs.getBool(_keyHaptic) ?? true;
      _sound = prefs.getBool(_keySound) ?? true;
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  Future<void> setHaptic(bool v) async {
    _haptic = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHaptic, v);
  }

  Future<void> setSound(bool v) async {
    _sound = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySound, v);
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
      SystemSound.play(SystemSoundType.click);
    }
  }

  void playSelect() {
    if (_haptic) HapticFeedback.selectionClick();
    if (_sound) SystemSound.play(SystemSoundType.click);
  }
}
