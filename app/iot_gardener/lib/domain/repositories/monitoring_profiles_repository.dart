import '../entities/monitoring_profile_params.dart';

abstract class MonitoringProfilesRepository {
  Future<List<MonitoringProfileParams>> getMonitoringProfiles();
  Future<void> addMonitoringProfile(MonitoringProfileParams params);
  Future<void> deleteMonitoringProfileByName(String name);
}