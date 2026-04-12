import '../entities/monitoring_profile_params.dart';
import '../repositories/monitoring_profiles_repository.dart';

class MonitoringProfilesDevice {
  final MonitoringProfilesRepository _repository;

  MonitoringProfilesDevice(this._repository);

  Future<List<MonitoringProfileParams>> getMonitoringProfiles() {
    return _repository.getMonitoringProfiles();
  }

  Future<void> addMonitoringProfile(MonitoringProfileParams params) {
    return _repository.addMonitoringProfile(params);
  }

  Future<void> deleteMonitoringProfileByName(String name) {
    return _repository.deleteMonitoringProfileByName(name);
  }
}