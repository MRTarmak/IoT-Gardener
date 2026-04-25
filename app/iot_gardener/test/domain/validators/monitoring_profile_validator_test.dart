import 'package:flutter_test/flutter_test.dart';
import 'package:iot_gardener/domain/entities/monitoring_profile_params.dart';
import 'package:iot_gardener/domain/validators/monitoring_profile_validator.dart';

void main() {
  group('MonitoringProfileValidator', () {
    test('returns error when all bounds are null', () {
      const profile = MonitoringProfileParams(name: 'Empty');

      final result = MonitoringProfileValidator.validate(profile);

      expect(result, 'Укажите хотя бы одну границу любого параметра');
    });

    test('returns error when min is greater than max', () {
      const profile = MonitoringProfileParams(
        name: 'InvalidRange',
        soilMoistureRange: (90, 30),
      );

      final result = MonitoringProfileValidator.validate(profile);

      expect(result, 'Максимальное значение не может быть меньше минимального');
    });

    test('returns range error for humidity above 100', () {
      const profile = MonitoringProfileParams(
        name: 'HumidityOutOfRange',
        airHumidityRange: (10, 120),
      );

      final result = MonitoringProfileValidator.validate(profile);

      expect(result, 'Влажность воздуха должна быть в диапазоне 0..100%');
    });

    test('returns null for valid profile', () {
      const profile = MonitoringProfileParams(
        name: 'Valid',
        soilMoistureRange: (20, 80),
        airTemperatureRange: (15, 27),
      );

      final result = MonitoringProfileValidator.validate(profile);

      expect(result, isNull);
    });
  });
}
