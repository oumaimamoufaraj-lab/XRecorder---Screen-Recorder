import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { light, dark, system }

abstract final class ThemePreferenceService {
  static const _key = 'app_theme_mode';

  static ThemeMode toThemeMode(AppThemePreference preference) {
    return switch (preference) {
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
      AppThemePreference.system => ThemeMode.system,
    };
  }

  static AppThemePreference fromThemeMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.dark => AppThemePreference.dark,
      ThemeMode.system => AppThemePreference.system,
      ThemeMode.light => AppThemePreference.light,
    };
  }

  static Future<AppThemePreference> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    return switch (value) {
      'dark' => AppThemePreference.dark,
      'system' => AppThemePreference.system,
      _ => AppThemePreference.light,
    };
  }

  static Future<void> save(AppThemePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, preference.name);
  }
}
