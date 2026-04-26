import '../entities/provisioning_result.dart';
import '../repositories/device_provisioning_repository.dart';

class ProvisionDevice {
  final DeviceProvisioningRepository repository;

  ProvisionDevice(this.repository);

  Future<ProvisioningResult> call({
    required String ssid,
    required String password,
  }) {
    return repository.sendWifiCredentials(ssid: ssid, password: password);
  }
}
