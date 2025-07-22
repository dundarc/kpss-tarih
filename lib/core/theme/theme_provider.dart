import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Bu provider, tema durumunu yönetir ve değişikliği dinleyen widget'ları günceller.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  // Başlangıçta sistem temasını kullanır.
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const String _themeKey = 'themeMode';

  // Cihaz hafızasından kayıtlı temayı yükler.
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    state = ThemeMode.values[themeIndex];
  }

  // Yeni temayı ayarlar ve cihaz hafızasına kaydeder.
  Future<void> setTheme(ThemeMode newTheme) async {
    if (newTheme == state) return;

    state = newTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, newTheme.index);
  }
}
