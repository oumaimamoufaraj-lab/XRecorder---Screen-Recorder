import 'package:flutter/material.dart';

import '../services/theme_preference_service.dart';

class ThemeController extends ChangeNotifier {
  AppThemePreference _preference = AppThemePreference.dark;

  AppThemePreference get preference => _preference;
  ThemeMode get themeMode => ThemePreferenceService.toThemeMode(_preference);

  Future<void> load() async {
    _preference = await ThemePreferenceService.load();
    notifyListeners();
  }

  Future<void> setPreference(AppThemePreference preference) async {
    if (_preference == preference) return;
    _preference = preference;
    await ThemePreferenceService.save(preference);
    notifyListeners();
  }
}

class ThemeScope extends InheritedWidget {
  const ThemeScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ThemeController controller;

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in widget tree');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) =>
      oldWidget.controller != controller;
}
