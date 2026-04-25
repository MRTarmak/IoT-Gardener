import 'package:flutter_test/flutter_test.dart';
import 'package:iot_gardener/data/repositories_impl/monitoring_profiles_repository_impl.dart';
import 'package:iot_gardener/domain/entities/monitoring_profile_params.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonitoringProfilesRepositoryImpl', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('adds and reads profile from storage', () async {
      final repository = MonitoringProfilesRepositoryImpl();
      const profile = MonitoringProfileParams(
        name: 'Tomato',
        soilMoistureRange: (30, 70),
      );

      await repository.addMonitoringProfile(profile);
      final stored = await repository.getMonitoringProfiles();

      expect(stored.length, 1);
      expect(stored.first.name, 'Tomato');
      expect(stored.first.soilMoistureRange, (30.0, 70.0));
    });

    test('throws when adding duplicate profile name', () async {
      final repository = MonitoringProfilesRepositoryImpl();
      const profile = MonitoringProfileParams(name: 'Duplicate');

      await repository.addMonitoringProfile(profile);

      expect(
        () => repository.addMonitoringProfile(profile),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('уже существует'),
          ),
        ),
      );
    });

    test('deletes existing profile and throws for missing one', () async {
      final repository = MonitoringProfilesRepositoryImpl();
      const profile = MonitoringProfileParams(name: 'ToDelete');

      await repository.addMonitoringProfile(profile);
      await repository.deleteMonitoringProfileByName('ToDelete');

      final afterDelete = await repository.getMonitoringProfiles();
      expect(afterDelete, isEmpty);

      expect(
        () => repository.deleteMonitoringProfileByName('ToDelete'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('не существует'),
          ),
        ),
      );
    });
  });
}
