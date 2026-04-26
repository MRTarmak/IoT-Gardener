import '../../domain/entities/provisioning_result.dart';
import '../../domain/repositories/device_provisioning_repository.dart';
import '../datasources/device_provisioning_datasource.dart';

class DeviceProvisioningRepositoryImpl implements DeviceProvisioningRepository {
  final DeviceProvisioningDatasource datasource;

  DeviceProvisioningRepositoryImpl(this.datasource);

  @override
  Future<ProvisioningResult> sendWifiCredentials({
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
