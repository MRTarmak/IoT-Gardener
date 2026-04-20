import '../../domain/entities/wifi_provisioning_result.dart';
import '../../domain/repositories/wifi_provisioning_repository.dart';
import '../datasources/wifi_provisioning_datasource.dart';

class WifiProvisioningRepositoryImpl implements WifiProvisioningRepository {
  final WifiProvisioningDatasource datasource;

  WifiProvisioningRepositoryImpl(this.datasource);

  @override
  Future<WifiProvisioningResult> sendWifiCredentials({
    required String ssid,
    required String password,
  }) {
    return datasource.sendWifiCredentials(ssid: ssid, password: password);
  }

  @override
  Future<bool> isDeviceReachable() {
    return datasource.isDeviceReachable();
  }
}
