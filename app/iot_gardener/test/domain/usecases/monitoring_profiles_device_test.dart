import 'package:flutter_test/flutter_test.dart';
import 'package:iot_gardener/domain/entities/monitoring_profile_params.dart';
import 'package:iot_gardener/domain/repositories/monitoring_profiles_repository.dart';
import 'package:iot_gardener/domain/usecases/monitoring_profiles_device.dart';

class _FakeMonitoringProfilesRepository implements MonitoringProfilesRepository {
  List<MonitoringProfileParams> stored = [];
  MonitoringProfileParams? lastAdded;
  String? lastDeleted;

  @override
  Future<void> addMonitoringProfile(MonitoringProfileParams params) async {
    lastAdded = params;
    stored.add(params);
  }

  @override
  Future<void> deleteMonitoringProfileByName(String name) async {
    lastDeleted = name;
    stored.removeWhere((profile) => profile.name == name);
  }

  @override
  Future<List<MonitoringProfileParams>> getMonitoringProfiles() async {
    return stored;
  }
}

void main() {
  group('MonitoringProfilesDevice', () {
    test('delegates getMonitoringProfiles', () async {
      final repo = _FakeMonitoringProfilesRepository()
        ..stored = [
          const MonitoringProfileParams(name: 'Tomato'),
        ];
      final device = MonitoringProfilesDevice(repo);

      final profiles = await device.getMonitoringProfiles();

      expect(profiles.length, 1);
      expect(profiles.first.name, 'Tomato');
    });

    test('delegates addMonitoringProfile', () async {
      final repo = _FakeMonitoringProfilesRepository();
      final device = MonitoringProfilesDevice(repo);
      const profile = MonitoringProfileParams(name: 'Pepper');

      await device.addMonitoringProfile(profile);

      expect(repo.lastAdded?.name, 'Pepper');
      expect(repo.stored.map((p) => p.name), contains('Pepper'));
    });

    test('delegates deleteMonitoringProfileByName', () async {
      final repo = _FakeMonitoringProfilesRepository()
        ..stored = [
          const MonitoringProfileParams(name: 'Basil'),
        ];
      final device = MonitoringProfilesDevice(repo);

      await device.deleteMonitoringProfileByName('Basil');

      expect(repo.lastDeleted, 'Basil');
      expect(repo.stored, isEmpty);
    });
  });
}
