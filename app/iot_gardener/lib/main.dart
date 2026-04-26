import 'package:flutter/material.dart';
import 'package:iot_gardener/domain/usecases/monitoring_profiles_device.dart';

import 'data/datasources/mqtt_telemetry_datasource_impl.dart';
import 'data/repositories_impl/monitoring_profiles_repository_impl.dart';
import 'data/repositories_impl/mqtt_telemetry_repository_impl.dart';
import 'domain/usecases/mqtt_device.dart';
import 'presentation/screens/root_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mqttTelemetryDatasource = MqttTelemetryDatasourceImpl();
    final mqttTelemetryRepository = MqttTelemetryRepositoryImpl(
      mqttTelemetryDatasource,
    );
    final mqttDevice = MqttDevice(mqttTelemetryRepository);
    final monitoringProfilesRepository = MonitoringProfilesRepositoryImpl();
    final monitoringProfilesDevice = MonitoringProfilesDevice(
      monitoringProfilesRepository,
    );

    return MaterialApp(
      title: 'IoT Gardener',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: RootScreen(
        mqttDevice: mqttDevice,
        monitoringProfilesDevice: monitoringProfilesDevice,
      ),
    );
  }
}
