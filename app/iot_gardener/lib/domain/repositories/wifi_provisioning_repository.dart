import '../entities/wifi_provisioning_result.dart';

abstract class WifiProvisioningRepository {
  Future<WifiProvisioningResult> sendWifiCredentials({
    required String ssid,
    required String password,
  });

  Future<List<String>?> checkConnection();
}
