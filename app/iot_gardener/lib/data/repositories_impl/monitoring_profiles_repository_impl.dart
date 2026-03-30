import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/monitoring_profile_params.dart';
import '../../domain/repositories/monitoring_profiles_repository.dart';

class MonitoringProfilesRepositoryImpl extends MonitoringProfilesRepository {
  static const String _profilesKey = 'monitoring_profiles';

  @override
  Future<List<MonitoringProfileParams>> getMonitoringProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = prefs.getStringList(_profilesKey) ?? [];

    return profiles
        .map(
          (raw) => MonitoringProfileParams.fromMap(
            jsonDecode(raw) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<void> addMonitoringProfile(MonitoringProfileParams params) async {
    // TODO
  }

  @override
  Future<void> deleteMonitoringProfileByName(String name) async {
    // TODO
  }
}
