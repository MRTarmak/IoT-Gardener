import '../../domain/entities/provisioning_result.dart';

abstract class DeviceProvisioningDatasource {
  Future<ProvisioningResult> sendWifiCredentials({
    required String ssid,
    required String password,
  });

  Future<bool> isDeviceReachable();
}
