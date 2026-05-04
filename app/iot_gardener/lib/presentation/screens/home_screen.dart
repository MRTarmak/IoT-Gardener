import 'package:flutter/material.dart';

import '../../domain/entities/monitoring_profile_params.dart';
import '../../domain/entities/telemetry_data.dart';
import '../widgets/telemetry_tile.dart';

class HomeScreen extends StatelessWidget {
  final bool isConnected;
  final TelemetryData? telemetry;
  final MonitoringProfileParams? selectedProfile;
  final VoidCallback onOpenSettings;

  const HomeScreen({
    super.key,
    required this.isConnected,
    required this.telemetry,
    required this.selectedProfile,
    required this.onOpenSettings,
  });

  bool _isOutOfRange(double value, (double?, double?) range) {
    final min = range.$1;
    final max = range.$2;

    if (min != null && value < min) return true;
    if (max != null && value > max) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/iot_gardener_icon.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 24),
            const Text(
              'Устройство не подключено',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Перейдите в Настройки для подключения',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Открыть настройки'),
            ),
          ],
        ),
      );
    }

    if (telemetry == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = selectedProfile;

    final soilTempOut =
        profile != null &&
        _isOutOfRange(telemetry!.soilTemperature, profile.soilTemperatureRange);
    final soilOut =
        profile != null &&
        _isOutOfRange(telemetry!.soilMoisture, profile.soilMoistureRange);
    final phOut =
        profile != null &&
        _isOutOfRange(telemetry!.soilPh, profile.soilPhRange);
    final airTempOut =
        profile != null &&
        _isOutOfRange(telemetry!.airTemperature, profile.airTemperatureRange);
    final airOut =
        profile != null &&
        _isOutOfRange(telemetry!.airHumidity, profile.airHumidityRange);
    final lightOut =
        profile != null && _isOutOfRange(telemetry!.light, profile.lightRange);

    final violations = <String>[
      if (soilTempOut) 'температура почвы',
      if (soilOut) 'влажность почвы',
      if (phOut) 'pH почвы',
      if (airTempOut) 'температура воздуха',
      if (airOut) 'влажность воздуха',
      if (lightOut) 'освещенность',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (profile == null)
            const Card(
              margin: EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Профиль мониторинга не выбран'),
                subtitle: Text(
                  'Выберите профиль во вкладке Профили, чтобы отслеживать выход за границы.',
                ),
              ),
            ),
          if (profile != null && violations.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Отклонение от профиля "${profile.name}"',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                subtitle: Text('Вне границ: ${violations.join(', ')}'),
              ),
            ),
          TelemetryTile(
            label: 'Температура почвы',
            value: '${telemetry!.soilTemperature.toStringAsFixed(1)} °C',
            icon: Icons.thermostat,
            isOutOfRange: soilTempOut,
          ),
          TelemetryTile(
            label: 'Влажность почвы',
            value: '${telemetry!.soilMoisture.toStringAsFixed(1)} %',
            icon: Icons.grass,
            isOutOfRange: soilOut,
          ),
          TelemetryTile(
            label: 'Кислотность почвы (pH)',
            value: telemetry!.soilPh.toStringAsFixed(2),
            icon: Icons.science,
            isOutOfRange: phOut,
          ),
          TelemetryTile(
            label: 'Температура воздуха',
            value: '${telemetry!.airTemperature.toStringAsFixed(1)} °C',
            icon: Icons.thermostat,
            isOutOfRange: airTempOut,
          ),
          TelemetryTile(
            label: 'Влажность воздуха',
            value: '${telemetry!.airHumidity.toStringAsFixed(1)} %',
            icon: Icons.water_drop,
            isOutOfRange: airOut,
          ),
          TelemetryTile(
            label: 'Освещенность',
            value: '${telemetry!.light.toStringAsFixed(0)} лк',
            icon: Icons.wb_sunny,
            isOutOfRange: lightOut,
          ),
          const SizedBox(height: 12),
          Text(
            'Последнее обновление: '
            '${telemetry!.receivedAt.hour.toString().padLeft(2, '0')}:'
            '${telemetry!.receivedAt.minute.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
