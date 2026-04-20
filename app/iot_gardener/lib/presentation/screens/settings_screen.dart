import 'package:flutter/material.dart';
import 'package:iot_gardener/presentation/widgets/wifi_provisioning_card.dart';

import '../widgets/mqtt_connection_card.dart';

class SettingsScreen extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final String? error;
  final Future<bool> Function() onConnect;
  final Future<void> Function() onDisconnect;

  const SettingsScreen({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.error,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        WifiProvisioningCard(),
        const SizedBox(height: 12),
        MqttConnectionCard(
          isConnected: isConnected,
          isConnecting: isConnecting,
          error: error,
          onConnect: onConnect,
          onDisconnect: onDisconnect,
        ),
      ],
    );
  }
}
