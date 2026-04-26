import 'package:flutter/material.dart';

import 'mqtt_connection_screen.dart';
import 'provisioning_screen.dart';

class SettingsScreen extends StatelessWidget {
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController clientIdController;
  final TextEditingController topicController;
  final bool isConnected;
  final bool isConnecting;
  final String? error;
  final Future<bool> Function() onConnect;
  final Future<void> Function() onDisconnect;

  const SettingsScreen({
    super.key,
    required this.hostController,
    required this.portController,
    required this.clientIdController,
    required this.topicController,
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Настройка Wi-Fi на устройстве',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Если устройство еще не подключено к вашей Wi-Fi сети, '
                  'пройдите провиженинг.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProvisioningScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.wifi_tethering),
                  label: const Text('Открыть провиженинг'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Подключение к MQTT брокеру',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Если устройство уже подключено к вашей Wi-Fi сети, '
                    'настройте подключение к MQTT брокеру.'),
                const SizedBox(height: 12),
                Text(
                  isConnected
                      ? 'Сейчас: подключено'
                      : (isConnecting ? 'Сейчас: подключение...' : 'Сейчас: отключено'),
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MqttConnectionScreen(
                          hostController: hostController,
                          portController: portController,
                          clientIdController: clientIdController,
                          topicController: topicController,
                          isConnected: isConnected,
                          isConnecting: isConnecting,
                          error: error,
                          onConnect: onConnect,
                          onDisconnect: onDisconnect,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.hub),
                  label: const Text('Открыть экран подключения MQTT'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
