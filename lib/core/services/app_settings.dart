import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide accessibility/appearance settings that must take effect instantly
/// (no restart) across the whole widget tree. The root [MaterialApp] listens to
/// these notifiers; Settings mutates them.
class AppSettings {
  static final AppSettings instance = AppSettings._();
  AppSettings._();

  /// Extra text scale on top of the OS setting (1.0 = none, 1.2 = larger).
  final ValueNotifier<double> extraTextScale = ValueNotifier(1.0);

  /// Reduce motion / calmer UI and skip full-screen celebrations.
  final ValueNotifier<bool> reduceMotion = ValueNotifier(false);

  /// Higher-contrast color treatment.
  final ValueNotifier<bool> highContrast = ValueNotifier(false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    extraTextScale.value = (prefs.getBool('large_text') ?? false) ? 1.2 : 1.0;
    reduceMotion.value = prefs.getBool('sensory_safe_ui') ?? false;
    highContrast.value = prefs.getBool('high_contrast') ?? false;
  }

  /// Re-read from prefs after Settings changes a value.
  Future<void> reload() => load();
}
