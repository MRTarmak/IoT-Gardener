import 'package:flutter/material.dart';

import 'data/datasources/mqtt_telemetry_datasource_impl.dart';
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
    final datasource = MqttTelemetryDatasourceImpl();
    final repository = MqttTelemetryRepositoryImpl(datasource);
    final mqttDevice = MqttDevice(repository);

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
      home: RootScreen(mqttDevice: mqttDevice),
    );
  }
}
