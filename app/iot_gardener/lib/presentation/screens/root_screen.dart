import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iot_gardener/domain/usecases/monitoring_profiles_device.dart';
import 'package:iot_gardener/presentation/screens/monitoring_profiles_screen.dart';

import '../../domain/entities/monitoring_profile_params.dart';
import '../../domain/entities/mqtt_connection_params.dart';
import '../../domain/entities/telemetry_data.dart';
import '../../domain/usecases/mqtt_device.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class RootScreen extends StatefulWidget {
  final MqttDevice mqttDevice;
  final MonitoringProfilesDevice monitoringProfilesDevice;

  const RootScreen({
    super.key,
    required this.mqttDevice,
    required this.monitoringProfilesDevice,
  });

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 1;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _settingsError;
  TelemetryData? _telemetry;

  final _hostController = TextEditingController(text: 'broker.emqx.io');
  final _portController = TextEditingController(text: '1883');
  final _clientIdController = TextEditingController(text: 'iot_gardener_app');
  final _topicController = TextEditingController(
    text: 'iot-gardener/telemetry',
  );

  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<TelemetryData>? _telemetrySubscription;

  MonitoringProfileParams? _selectedProfile;

  @override
  void initState() {
    super.initState();

    _connectionSubscription = widget.mqttDevice.connectionStream.listen((
      connected,
    ) {
      if (!mounted) return;
      setState(() {
        _isConnected = connected;
      });
    });

    _telemetrySubscription = widget.mqttDevice.telemetryStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _telemetry = data;
      });
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _telemetrySubscription?.cancel();

    _hostController.dispose();
    _portController.dispose();
    _clientIdController.dispose();
    _topicController.dispose();

    unawaited(widget.mqttDevice.dispose());

    super.dispose();
  }

  Future<bool> _connectMqtt() async {
    final port = int.tryParse(_portController.text.trim());
    if (port == null) {
      setState(() {
        _settingsError = 'Порт должен быть числом';
      });
      return false;
    }

    final params = MqttConnectionParams(
      host: _hostController.text.trim(),
      port: port,
      clientId: _clientIdController.text.trim(),
      topic: _topicController.text.trim(),
    );

    setState(() {
      _isConnecting = true;
      _settingsError = null;
    });

    final isConnected = await widget.mqttDevice.connect(params);

    if (!mounted) return false;

    setState(() {
      _isConnecting = false;
      if (!isConnected) {
        _settingsError = 'Не удалось подключиться к MQTT брокеру';
      }
    });

    return isConnected;
  }

  Future<void> _disconnectMqtt() async {
    await widget.mqttDevice.disconnect();
  }

  void _openSettingsTab() {
    setState(() {
      _currentIndex = 2;
    });
  }

  Future<List<MonitoringProfileParams>> _getMonitoringProfiles() async {
    return widget.monitoringProfilesDevice.getMonitoringProfiles();
  }

  Future<void> _addMonitoringProfile(MonitoringProfileParams params) async {
    try {
      await widget.monitoringProfilesDevice.addMonitoringProfile(params);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении профиля: $e')),
      );
    }
  }

  Future<void> _deleteMonitoringProfileByName(String name) async {
    try {
      await widget.monitoringProfilesDevice.deleteMonitoringProfileByName(name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении профиля: $e')),
      );
    }
  }

  void _selectMonitoringProfile({MonitoringProfileParams? profile}) {
    setState(() {
      _selectedProfile = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'IoT Gardener',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          MonitoringProfilesScreen(
            getProfiles: _getMonitoringProfiles,
            onAddProfile: _addMonitoringProfile,
            onDeleteProfile: _deleteMonitoringProfileByName,
            onSelectProfile: _selectMonitoringProfile,
            selectedProfileName: _selectedProfile?.name,
          ),
          HomeScreen(
            isConnected: _isConnected,
            telemetry: _telemetry,
            selectedProfile: _selectedProfile,
            onOpenSettings: _openSettingsTab,
          ),
          SettingsScreen(
            hostController: _hostController,
            portController: _portController,
            clientIdController: _clientIdController,
            topicController: _topicController,
            isConnected: _isConnected,
            isConnecting: _isConnecting,
            error: _settingsError,
            onConnect: _connectMqtt,
            onDisconnect: _disconnectMqtt,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'Профили'),
          NavigationDestination(icon: Icon(Icons.home), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}
