import 'package:flutter_test/flutter_test.dart';
import 'package:iot_gardener/domain/entities/monitoring_profile_params.dart';
import 'package:iot_gardener/presentation/formatters/monitoring_profile_formatter.dart';

void main() {
  group('MonitoringProfileFormatter', () {
    test('returns fallback when no bounds provided', () {
      const profile = MonitoringProfileParams(name: 'Empty');

      final text = MonitoringProfileFormatter.formatProfileDetails(profile);

      expect(text, 'Границы не заданы');
    });

    test('formats mixed ranges and one-sided bounds', () {
      const profile = MonitoringProfileParams(
        name: 'Mixed',
        soilMoistureRange: (20, 40),
        airHumidityRange: (null, 70),
        temperatureRange: (18.5, null),
      );

      final text = MonitoringProfileFormatter.formatProfileDetails(profile);

      expect(text, 'Почва: 20% - 40% · Воздух: <= 70% · Темп: >= 18.50°C');
    });

    test('formats decimals with two digits and integers without decimals', () {
      const profile = MonitoringProfileParams(
        name: 'Precision',
        soilPhRange: (6.2, 7),
      );

      final text = MonitoringProfileFormatter.formatProfileDetails(profile);

      expect(text, 'pH: 6.20 - 7');
    });
  });
}
