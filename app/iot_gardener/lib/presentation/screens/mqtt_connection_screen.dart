import 'package:flutter/material.dart';

class MqttConnectionScreen extends StatefulWidget {
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController clientIdController;
  final TextEditingController topicController;
  final bool isConnected;
  final bool isConnecting;
  final String? error;
  final Future<bool> Function() onConnect;
  final Future<void> Function() onDisconnect;

  const MqttConnectionScreen({
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
  State<MqttConnectionScreen> createState() => _MqttConnectionScreenState();
}

class _MqttConnectionScreenState extends State<MqttConnectionScreen> {
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
    final keyboardBottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Подключение MQTT')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboardBottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.hub, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Подключитесь к MQTT брокеру',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Названия хоста и топика, а также порт вы можете узнать в настройках вашего устройства.\n'
                'ID клиента может быть любым уникальным идентификатором на ваше усмотрение.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: widget.hostController,
                decoration: const InputDecoration(
                  labelText: 'Хост',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: widget.portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Порт',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: widget.clientIdController,
                decoration: const InputDecoration(
                  labelText: 'Client ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: widget.topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
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
      ),
    );
  }
}
