import 'package:shared_preferences/shared_preferences.dart';

class DeveloperSettingsService {
  static const _developerModeKey = 'developer_mode_enabled';

  Future<bool> isDeveloperModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_developerModeKey) ?? false;
  }

  Future<void> setDeveloperModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_developerModeKey, enabled);
  }
}
