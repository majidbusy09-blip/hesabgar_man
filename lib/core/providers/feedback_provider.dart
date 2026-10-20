import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../storage/local_store.dart';

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
