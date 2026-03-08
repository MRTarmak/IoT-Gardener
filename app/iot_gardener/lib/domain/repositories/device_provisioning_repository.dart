import '../entities/provisioning_result.dart';

abstract class DeviceProvisioningRepository {
  Future<ProvisioningResult> sendWifiCredentials({
    required String ssid,
    required String password,
  });

  Future<bool> isDeviceReachable();
}
