import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class PreferencesService {
  const PreferencesService(this._preferences);
  static const _settingsKey = 'app_settings_v1';
  final SharedPreferences _preferences;

  AppSettings load() {
    final encoded = _preferences.getString(_settingsKey);
    if (encoded == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
    } on Object {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) =>
      _preferences.setString(_settingsKey, jsonEncode(settings.toJson()));
}
