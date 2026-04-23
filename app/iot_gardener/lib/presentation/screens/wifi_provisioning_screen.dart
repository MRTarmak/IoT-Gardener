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
  String? _selectedSsid;
  final _passwordController = TextEditingController();

  final _usecase = WifiProvisionDevice(
    WifiProvisioningRepositoryImpl(WifiProvisioningDatasource()),
  );

  List<String>? _ssidList;

  _ProvisioningStep _currentStep = _ProvisioningStep.connectToDevice;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
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
      _selectedSsid = null;
      _passwordController.clear();
    });

    _ssidList = await _usecase.checkConnection();

    if (!mounted) return;

    if (_ssidList != null) {
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
    if (_selectedSsid == null || _selectedSsid!.isEmpty) {
      setState(() => _errorMessage = 'Выберите Wi-Fi сеть из списка');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _usecase(
      ssid: _selectedSsid!,
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
    final ssids = _ssidList;
    final hasSsids = ssids != null && ssids.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.wifi, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          'Выберите вашу Wi-Fi сеть в списке ниже',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Устройство подключится к этой сети для передачи данных.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        if (hasSsids)
          Expanded(
            child: ListView.builder(
              itemCount: ssids.length,
              itemBuilder: (context, index) {
                final ssid = ssids[index];
                final isSelected = ssid == _selectedSsid;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Material(
                    color: isSelected
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      title: Text(ssid),
                      leading: const Icon(Icons.wifi),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedSsid = ssid;
                          _errorMessage = null;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text(
                'Что-то пошло не так, и мы не смогли получить список Wi-Fi сетей. Попробуйте снова.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          enabled: _selectedSsid != null,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: _selectedSsid == null
                ? 'Сначала выберите сеть'
                : 'Пароль для $_selectedSsid',
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
        const SizedBox(height: 12),
        if (_errorMessage != null) ...[
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton(
          onPressed: _isLoading || _selectedSsid == null
              ? null
              : _sendCredentials,
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
