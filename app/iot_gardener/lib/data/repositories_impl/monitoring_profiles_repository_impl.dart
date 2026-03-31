import 'dart:convert' hide Converter;

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/monitoring_profile_params.dart';
import '../../domain/repositories/monitoring_profiles_repository.dart';
import '../../domain/utils/converter.dart';

class MonitoringProfilesRepositoryImpl extends MonitoringProfilesRepository {
  static const String _profilesKey = 'monitoring_profiles';
  static const String _profilesNamesKey = 'monitoring_profiles_names';

  @override
  Future<List<MonitoringProfileParams>> getMonitoringProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(_profilesNamesKey) ?? [];

    List<MonitoringProfileParams> profiles = [];
    for (var name in names) {
      final jsonStr = prefs.getString('$_profilesKey$name');
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr);
        profiles.add(
          MonitoringProfileParams.fromMap(json as Map<String, dynamic>),
        );
      }
    }
    return profiles;
  }

  @override
  Future<void> addMonitoringProfile(MonitoringProfileParams params) async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(_profilesNamesKey) ?? [];
    if (!names.contains(params.name)) {
      final jsonStr = jsonEncode(Converter.toMap(params));
      await prefs.setString('$_profilesKey${params.name}', jsonStr);
      names.add(params.name);
      await prefs.setStringList(_profilesNamesKey, names);
      return;
    }
    throw Exception('Профиль "${params.name}" уже существует');
  }

  @override
  Future<void> deleteMonitoringProfileByName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(_profilesNamesKey) ?? [];
    if (names.contains(name)) {
      await prefs.remove('$_profilesKey$name');
      names.remove(name);
      await prefs.setStringList(_profilesNamesKey, names);
      return;
    }
    throw Exception('Профиль "$name" не существует');
  }
}
