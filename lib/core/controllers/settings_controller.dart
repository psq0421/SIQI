import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../services/preferences_service.dart';

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._preferences) : super(_preferences.load());
  final PreferencesService _preferences;

  Future<void> update(
    AppSettings Function(AppSettings current) transform,
  ) async {
    state = transform(state);
    await _preferences.save(state);
  }

  Future<void> replace(AppSettings settings) async {
    state = settings;
    await _preferences.save(state);
  }
}
