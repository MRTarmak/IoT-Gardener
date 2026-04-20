import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/repositories_impl/wifi_provisioning_repository_impl.dart';
import '../../domain/entities/wifi_provisioning_result.dart';
import '../../domain/usecases/wifi_provision_device.dart';
import '../../data/datasources/wifi_provisioning_datasource.dart';

class WifiProvisioningScreen extends StatefulWidget {
  const WifiProvisioningScreen({super.key});

  @override
  State<WifiProvisioningScreen> createState() => _WifiProvisioningScreenState();
}

class _WifiProvisioningScreenState extends State<WifiProvisioningScreen> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();

  final _usecase = WifiProvisionDevice(
    WifiProvisioningRepositoryImpl(WifiProvisioningDatasource()),
  );

  _ProvisioningStep _currentStep = _ProvisioningStep.connectToDevice;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static const _platform = MethodChannel('iot_gardener/wifi');

  Future<void> _openWifiSettings() async {
    try {
      await _platform.invokeMethod('openWifiSettings');
    } on PlatformException {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Инструкция'),
          content: const Text(
            'Не удалось открыть настройки Wi-Fi автоматически.\n'
            'Пожалуйста, откройте настройки Wi-Fi вручную и подключитесь к сети устройства.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _checkDeviceConnection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final reachable = await _usecase.isDeviceReachable();

    if (!mounted) return;

    if (reachable) {
      setState(() {
        _currentStep = _ProvisioningStep.enterWifiCredentials;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Устройство не найдено. Убедитесь, что вы подключены к Wi-Fi сети устройства.';
      });
    }
  }

  Future<void> _sendCredentials() async {
    if (_ssidController.text.isEmpty) {
      setState(() => _errorMessage = 'Введите название Wi-Fi сети');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _usecase(
      ssid: _ssidController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    switch (result) {
      case WifiProvisioningResult.success:
        setState(() {
          _currentStep = _ProvisioningStep.done;
          _isLoading = false;
        });
      case WifiProvisioningResult.deviceError:
        setState(() {
          _isLoading = false;
          _errorMessage = 'Устройство вернуло ошибку. Попробуйте ещё раз.';
        });
      case WifiProvisioningResult.connectionFailed:
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Не удалось связаться с устройством. Проверьте подключение.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подключение устройства')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: switch (_currentStep) {
          _ProvisioningStep.connectToDevice => _buildConnectStep(),
          _ProvisioningStep.enterWifiCredentials => _buildCredentialsStep(),
          _ProvisioningStep.done => _buildDoneStep(),
        },
      ),
    );
  }

  Widget _buildConnectStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.wifi_tethering, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          'Подключитесь к Wi-Fi сети устройства',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Откройте настройки Wi-Fi на телефоне и подключитесь к сети '
          'с именем «ESP_Config». После этого вернитесь в приложение '
          'и нажмите кнопку ниже.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _openWifiSettings,
          child: const Text('Открыть настройки Wi-Fi'),
        ),
        const Spacer(),
        if (_errorMessage != null) ...[
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton(
          onPressed: _isLoading ? null : _checkDeviceConnection,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Продолжить'),
        ),
      ],
    );
  }

  Widget _buildCredentialsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.wifi, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          'Введите данные вашей Wi-Fi сети',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Устройство подключится к этой сети для передачи данных.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _ssidController,
          decoration: const InputDecoration(
            labelText: 'Название сети (SSID)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.wifi),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Пароль',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const Spacer(),
        if (_errorMessage != null) ...[
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton(
          onPressed: _isLoading ? null : _sendCredentials,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Отправить'),
        ),
      ],
    );
  }

  Widget _buildDoneStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 100, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          'Устройство настроено!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Устройство подключается к вашей Wi-Fi сети. '
          'Переключитесь обратно на свою домашнюю сеть.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Готово'),
        ),
      ],
    );
  }
}

enum _ProvisioningStep { connectToDevice, enterWifiCredentials, done }
