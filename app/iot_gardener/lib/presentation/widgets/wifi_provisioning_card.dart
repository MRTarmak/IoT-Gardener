import 'package:flutter/material.dart';

import '../screens/wifi_provisioning_screen.dart';

class WifiProvisioningCard extends StatelessWidget {
  const WifiProvisioningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
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
              'Если устройство еще не подключено к вашей '
              'Wi-Fi сети, пройдите провиженинг.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WifiProvisioningScreen()),
                );
              },
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Открыть провиженинг'),
            ),
          ],
        ),
      ),
    );
  }
}
