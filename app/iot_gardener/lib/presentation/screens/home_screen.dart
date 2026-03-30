import 'package:flutter/material.dart';

import '../../domain/entities/telemetry_data.dart';
import '../widgets/telemetry_tile.dart';

class HomeScreen extends StatelessWidget {
  final bool isConnected;
  final TelemetryData? telemetry;
  final VoidCallback onOpenSettings;

  const HomeScreen({
    super.key,
    required this.isConnected,
    required this.telemetry,
    required this.onOpenSettings,
  });

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TelemetryTile(
            label: 'Влажность почвы',
            value: '${telemetry!.soilMoisture.toStringAsFixed(1)} %',
            icon: Icons.grass,
          ),
          TelemetryTile(
            label: 'Влажность воздуха',
            value: '${telemetry!.airHumidity.toStringAsFixed(1)} %',
            icon: Icons.water_drop,
          ),
          TelemetryTile(
            label: 'Кислотность почвы (pH)',
            value: telemetry!.soilPh.toStringAsFixed(2),
            icon: Icons.science,
          ),
          TelemetryTile(
            label: 'Температура',
            value: '${telemetry!.temperature.toStringAsFixed(1)} °C',
            icon: Icons.thermostat,
          ),
          TelemetryTile(
            label: 'Освещенность',
            value: '${telemetry!.light.toStringAsFixed(0)} лк',
            icon: Icons.wb_sunny,
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
