import '../entities/wifi_provisioning_result.dart';
import '../repositories/wifi_provisioning_repository.dart';

class WifiProvisionDevice {
  final WifiProvisioningRepository repository;

  WifiProvisionDevice(this.repository);

  Future<WifiProvisioningResult> call({
    required String ssid,
    required String password,
  }) {
    return repository.sendWifiCredentials(ssid: ssid, password: password);
  }

  Future<List<String>?> checkConnection() {
    return repository.checkConnection();
  }
}
