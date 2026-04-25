import 'package:flutter/material.dart';

class MqttConnectionCard extends StatefulWidget {
  final bool isConnected;
  final bool isConnecting;
  final String? error;
  final Future<bool> Function() onConnect;
  final Future<void> Function() onDisconnect;

  const MqttConnectionCard({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.error,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  State<MqttConnectionCard> createState() => _MqttConnectionCardState();
}

class _MqttConnectionCardState extends State<MqttConnectionCard> {
  late bool _isConnected;
  late bool _isConnecting;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isConnected = widget.isConnected;
    _isConnecting = widget.isConnecting;
    _error = widget.error;
  }

  Future<void> _handleConnectionToggle() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    if (_isConnected) {
      await widget.onDisconnect();
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _isConnected = false;
      });
      return;
    }

    final connected = await widget.onConnect();
    if (!mounted) return;

    setState(() {
      _isConnecting = false;
      _isConnected = connected;
      if (!connected) {
        _error = 'Не удалось подключиться к MQTT брокеру';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
            Text(
              'Если устройство уже подключено к вашей Wi-Fi сети (светодиод горит), '
              'настройте подключение к MQTT брокеру.',
            ),
            const SizedBox(height: 12),
            Text(
              _isConnected
                  ? 'Сейчас: подключено'
                  : (_isConnecting
                        ? 'Сейчас: подключение...'
                        : 'Сейчас: отключено'),
              style: TextStyle(
                color: _isConnected ? Colors.green : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isConnecting ? null : _handleConnectionToggle,
              icon: Icon(_isConnected ? Icons.link_off : Icons.link),
              label: Text(
                _isConnecting
                    ? 'Подключение...'
                    : (_isConnected ? 'Отключиться' : 'Подключиться'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
